# Mackerel ログ送信基盤 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** lily クラスタの Pod ログ、journald、Kubernetes Events を OpenTelemetry Collector 経由で Mackerel に送る基盤を用意する。

**Architecture:** OpenTelemetry Collector を DaemonSet（Pod ログ）と Deployment（Kubernetes Events）の 2 リリースで新設し、Mackerel への送信を Collector に一元化する。journald は `journalctl` を持たない公式イメージの制約から、既存の Alloy に読み取らせて OTLP で Collector に渡す。既存の Alloy と Loki の経路は評価期間中そのまま並走させる。

**Tech Stack:** Kubernetes, Kustomize, Helm, OpenTelemetry Collector (`otel/opentelemetry-collector-k8s`), Grafana Alloy, ArgoCD, 1Password Connect

設計の根拠は `docs/superpowers/specs/2026-08-01_mackerel-log-ingestion.md` にある。

## Global Constraints

- **YAML のキー順序は ESLint が強制する**。`k8s/**/*.{yml,yaml}` に `yml/sort-keys` が適用され、トップレベルは `apiVersion`, `kind`, `metadata`, `namespace`, `type`, `spec`, `images`, `helmCharts`, `commonLabels`, `resources`, `configMapGenerator` の順、それ以外は昇順（asc）である。`metadata` 配下は `name`, `namespace`, `annotations`, 以降昇順。**各タスクのコミット前に `pnpm eslint --fix` を実行する**。
- **kube-linter は `addAllBuiltIn: true`** で動作する。除外は `.kube-linter.yaml` に列挙されたものだけで、`privileged-container`、`run-as-non-root`、`no-read-only-root-fs`、`privilege-escalation-container`、`unset-capabilities` は有効である。
- **Collector は非 root（uid 10001）で動かす**。`privileged: false`、`allowPrivilegeEscalation: false`、`capabilities.drop: [ALL]`、`readOnlyRootFilesystem: true`、`seccompProfile.type: RuntimeDefault` を必ず設定する。
- **Mackerel の OTLP エンドポイント**：`https://otlp-vaxila.mackerelio.com`、認証ヘッダーは `Mackerel-Api-Key`。
- **Mackerel API キーの 1Password itemPath**：`vaults/4mogpcwrvtvsnpooum4vcevwkm/items/lplwhjpvwu7x4vblj424d67rba`、Secret のキー名は `apiKey`。
- **稼働中の Alloy の securityContext は変更しない**。Task 7 で `config.alloy` にのみ追記する。
- **OpenTelemetry Collector chart のバージョン**：`0.159.0`（既存の kustomization と同じ）。
- **コミットメッセージは日本語の Conventional Commits 形式**とし、`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` を付ける。

### 全タスク共通の検証コマンド

```bash
# kustomize build がすべてのディレクトリで通ることを確認する
mise exec -- go run ./cmd/build-manifests

# YAML のキー順序を含む lint
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint

# マニフェストの静的検査
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

**kube-linter はリポジトリ全体で 633 件の既存の指摘を出す**（2026-08-01 時点のベースライン）。
`exit code 1` は正常であり、判定は「変更によって新規の指摘が増えていないこと」で行う。

```bash
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s > /tmp/after.log 2>&1
git stash
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s > /tmp/before.log 2>&1
git stash pop
diff /tmp/before.log /tmp/after.log && echo "新規の指摘なし"
```

`go`、`pnpm`、`kubectl`、`kustomize`、`kube-linter` はいずれも **mise 経由で実行する**。
システムの PATH には入っていないか、バージョンが mise.toml と不一致である。

---

## File Structure

| ファイル | 責務 |
| --- | --- |
| `k8s/apps/nebula/kustomization.yaml` | nebula のログレベル設定（Task 1） |
| `k8s/system/traefik/lily/values.yaml` | Traefik のアクセスログのフィールド設定（Task 2） |
| `k8s/system/opentelemetry-collector/resources/namespace.yaml` | Namespace（既存、変更なし） |
| `k8s/system/opentelemetry-collector/resources/secret.yaml` | Mackerel API キーの配布（Task 3 で新規作成） |
| `k8s/system/opentelemetry-collector/kustomization.yaml` | Collector の Helm リリース 2 つ（Task 3, 4, 5, 6 で段階的に構築） |
| `k8s/system/argo-cd/resources/application-set-lily.yaml` | ArgoCD への登録（Task 3） |
| `k8s/apps/grafana-alloy/config/config.alloy` | journald の OTLP 橋渡し（Task 7） |

---

## Task 1: nebula のログレベル是正

nebula backend が DEBUG レベルで SQL クエリの全文を出力しており、クラスタ全体のログ量の 58%（1.72 GB/日）を占めている。
backend と worker は同じ `backend-config` ConfigMap を参照しているため、1 行の追加で両方に効く。

**Files:**
- Modify: `k8s/apps/nebula/kustomization.yaml:87-100`（`configMapGenerator` の `backend-config`）

- [ ] **Step 1: 変更前のログ量を記録する**

```bash
mise exec -- kubectl get --raw \
  "/api/v1/namespaces/grafana-loki/services/loki:3100/proxy/loki/api/v1/query?query=sum(bytes_over_time(%7Bnamespace%3D%22nebula%22%7D%5B1h%5D))"
```

出力の `value[1]` を控える。基準値は約 7.5e7（75 MB/h）である。

- [ ] **Step 2: アプリケーションが `LOG_LEVEL` を参照するか確認する**

nebula のアプリケーションが実際にこの環境変数を読むかは未確認である。
まず現在の Deployment に設定されている環境変数を確認する。
イメージが distroless の場合 `kubectl exec` で `env` を実行できないため、マニフェストから読む。

```bash
mise exec -- kubectl get deploy backend -n nebula \
  -o jsonpath='{.spec.template.spec.containers[0].env[*].name}{"\n"}'
mise exec -- kubectl get cm -n nebula -o name | grep backend-config
```

調査時点では `SERVER_ADDRESS` のみが設定されており、ログレベルの指定は存在しなかった。

次に nebula アプリケーションのソースで設定名を確認する。

```bash
gh search code --repo SlashNephy/nebula "LOG_LEVEL" --limit 5 \
  || echo "GitHub 検索で見つからない。リポジトリを clone して確認する"
```

`LOG_LEVEL` 以外の名前だった場合は、以降のステップの変数名をその名前に置き換える。
設定名が特定できない場合は、この Task を中断してユーザーに確認する。
発生源の是正は Collector 側の除外でも代替できるが、その判断はユーザーが行う。

- [ ] **Step 3: ConfigMap にログレベルを追加する**

`k8s/apps/nebula/kustomization.yaml` の `configMapGenerator` を次のように変更する。
`literals` は既存の並びを保ち、末尾に追加する（`yml/sort-sequence-values` の対象外であることを `pnpm eslint` で確認する）。

```yaml
configMapGenerator:
  - name: backend-config
    literals:
      - SERVER_ORIGIN=https://nebula.starry.blue
      - FRONTEND_ORIGIN=https://nebula.starry.blue
      - COOKIE_DOMAIN=nebula.starry.blue
      - MEDIA_STORAGE_LOCAL_DIRECTORY=/app/media
      - AVATAR_STORAGE_LOCAL_DIRECTORY=/app/avatars
      - THUMBNAIL_STORAGE_LOCAL_DIRECTORY=/app/thumbnails
      - ML_BASE_URL=http://ml:8083
      - XCTID_BASE_URL=http://xctid:8084
      - INSTAGRAM_BASE_URL=http://instagram:8085
      - YTDLP_BASE_URL=http://ytdlp:8086
      - FFMPEG_BASE_URL=http://ffmpeg:8087
      # DEBUG では SQL クエリの全文が出力され、クラスタ全体のログ量の 58% を占めていた
      - LOG_LEVEL=info
```

- [ ] **Step 4: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

期待：`build-manifests` と `eslint` はエラーなし。`build-manifests` は `k8s/apps/nebula` を含む全ディレクトリのビルドに成功する。kube-linter はベースラインとの diff が空である。

- [ ] **Step 5: コミット**

```bash
git add k8s/apps/nebula/kustomization.yaml
git commit -F - <<'EOF'
fix(nebula): 本番のログレベルを info に設定

backend がアプリケーションの既定値である DEBUG で稼働しており、
SQL クエリの全文を出力していた。クラスタ全体のログ量 2.97 GB/日の
うち 1.72 GB/日 (58%) をこのデバッグログが占めていた。

backend と worker は同じ ConfigMap を参照するため、両方に効く。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 6: デプロイ後にログ量の減少を確認する**

ArgoCD が同期し Pod が再起動した後、Step 1 と同じクエリを実行する。

```bash
mise exec -- kubectl rollout status deploy/backend -n nebula --timeout=5m
# Pod 再起動から 1 時間以上経過してから実行する
mise exec -- kubectl get --raw \
  "/api/v1/namespaces/grafana-loki/services/loki:3100/proxy/loki/api/v1/query?query=sum(bytes_over_time(%7Bnamespace%3D%22nebula%22%7D%5B1h%5D))"
```

期待：約 7.5e7 から 1.0e7 程度（10 MB/h 前後）に減少する。
減少しない場合、アプリケーションが `LOG_LEVEL` を参照していない。Step 2 に戻る。

---

## Task 2: Traefik のアクセスログのヘッダー削減

Traefik のアクセスログは 1 レコード平均 3,554 bytes で、その 73.5% を HTTP ヘッダーが占めている。
`defaultmode` を `keep` から `drop` に反転し、必要なヘッダーだけを明示的に残す。

**Files:**
- Modify: `k8s/system/traefik/lily/values.yaml:79-96`（`logs.access.fields`）

- [ ] **Step 1: 変更前のレコードサイズを記録する**

```bash
mise exec -- kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=500 \
  | python3 -c "
import sys
lines = [l for l in sys.stdin if l.startswith('{')]
print(f'{len(lines)} 行, 平均 {sum(len(l) for l in lines)/len(lines):.0f} bytes/rec')
"
```

期待：平均 3,500 bytes 前後。

- [ ] **Step 2: values.yaml のヘッダー設定を反転する**

`k8s/system/traefik/lily/values.yaml` の `logs.access.fields.headers` を次のように置き換える。
`general` セクションは変更しない。

```yaml
logs:
  access:
    enabled: true
    # https://docs.traefik.io/observability/access-logs/#limiting-the-fieldsincluding-headers
    fields:
      general:
        defaultmode: keep
        names:
          ClientAddr: drop # ClientHost:ClientPort の組み合わせなので不要
          StartLocal: drop # time で十分
          StartUTC: drop
      headers:
        # 全ヘッダーを記録すると 1 レコード 3,554 bytes に達し、その 73.5% を
        # ヘッダーが占めていた。drop を既定にすることで、新しい機密ヘッダーが
        # 増えても明示的に keep しない限りログに載らない。
        defaultmode: drop
        names:
          Accept-Language: keep
          # Cloudflare のジオ情報。緯度経度 (Cf-Iplatitude/Cf-Iplongitude)、
          # 郵便番号、タイムゾーンは所在地の特定精度が高すぎるため keep しない。
          Cf-Connecting-Ip: keep
          Cf-Ipcity: keep
          Cf-Ipcountry: keep
          Cf-Ray: keep
          Cf-Visitor: keep
          Origin: keep
          Referer: keep
          Sec-Ch-Ua: keep
          Sec-Ch-Ua-Mobile: keep
          Sec-Ch-Ua-Platform: keep
          Sec-Fetch-Dest: keep
          Sec-Fetch-Mode: keep
          Sec-Fetch-Site: keep
          User-Agent: keep
          X-Real-Ip: keep
    format: json
  general:
    level: INFO
```

`Authorization`、`Cookie`、`X-Authentik-Jwt` の `redact` 指定は削除する。
`defaultmode: drop` により、これらは明示的に keep しない限り記録されない。

- [ ] **Step 3: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

期待：`build-manifests` と `eslint` はエラーなし。kube-linter はベースラインとの diff が空である。

- [ ] **Step 4: コミット**

```bash
git add k8s/system/traefik/lily/values.yaml
git commit -F - <<'EOF'
perf(traefik): アクセスログのヘッダーを必要なものだけに絞る

1 レコード平均 3,554 bytes のうち 73.5% を HTTP ヘッダーが占めており、
origin_* は downstream_* とほぼ重複、固定セキュリティヘッダーは毎回
同じ値を返すため情報量がなかった。

defaultmode を drop に反転し、クライアント識別とジオ情報に必要な 16 個
のみを keep する。これにより Authorization と Cookie の redact 指定が
不要になり、新しい機密ヘッダーが増えても指定漏れが起きなくなる。

Cloudflare の緯度経度と郵便番号は所在地の特定精度が高いため keep しない。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: デプロイ後にレコードサイズの減少を確認する**

```bash
mise exec -- kubectl rollout status deploy/traefik -n traefik --timeout=5m
```

Step 1 と同じコマンドを実行する。
期待：平均 1,400 bytes 前後（約 60% 減）。

あわせて機密ヘッダーが記録されていないことを確認する。

```bash
COUNT=$(mise exec -- kubectl logs -n traefik -l app.kubernetes.io/name=traefik --tail=500 \
  | grep -ciE '"(request|downstream|origin)_(authorization|cookie|x-authentik-jwt)"' || true)
echo "機密ヘッダーを含む行: ${COUNT}"
```

期待：`0` である。
0 でない場合、`defaultmode: drop` が反映されていない。Pod が再起動しているかを確認する。

---

## Task 3: Collector の土台と Pod ログの読み取り確認

Collector を非 root で立ち上げ、`/var/log/pods` を読めることを確認する。
このタスクでは Mackerel には送らず、`debug` exporter で読み取りだけを検証する。
非 root での読み取り可否が設計上最大の未検証事項であり、先に潰しておく。

**Files:**
- Create: `k8s/system/opentelemetry-collector/resources/secret.yaml`
- Modify: `k8s/system/opentelemetry-collector/kustomization.yaml`（全面書き換え）
- Modify: `k8s/system/argo-cd/resources/application-set-lily.yaml`（`system` セクションに追加）

**Interfaces:**
- Produces: Namespace `opentelemetry-collector`、Secret `mackerel-api-key`（キー `apiKey`）、Helm リリース `otel-agent`（DaemonSet）

- [ ] **Step 1: Secret のマニフェストを作成する**

`k8s/system/opentelemetry-collector/resources/secret.yaml` を新規作成する。
既存の `k8s/system/mackerel-operator/resources/secret.yaml` と同じ 1Password のアイテムを参照する。

```yaml
apiVersion: onepassword.com/v1
kind: OnePasswordItem
metadata:
  name: mackerel-api-key

spec:
  itemPath: vaults/4mogpcwrvtvsnpooum4vcevwkm/items/lplwhjpvwu7x4vblj424d67rba
```

- [ ] **Step 2: kustomization.yaml を書き換える**

`k8s/system/opentelemetry-collector/kustomization.yaml` を全面的に置き換える。
既存の設定は `mode: deployment` でありながら DaemonSet 前提の `logsCollection` preset を有効にしており、そのままでは使えない。

このステップでは `debug` exporter のみを設定し、Mackerel には送らない。

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: opentelemetry-collector

helmCharts:
  # https://artifacthub.io/packages/helm/opentelemetry-helm/opentelemetry-collector
  - name: opentelemetry-collector
    releaseName: otel-agent
    namespace: opentelemetry-collector
    version: 0.159.0
    repo: https://open-telemetry.github.io/opentelemetry-helm-charts
    valuesInline:
      config:
        exporters:
          debug:
            verbosity: basic
        service:
          pipelines:
            logs:
              exporters:
                - debug
      image:
        repository: otel/opentelemetry-collector-k8s
      mode: daemonset
      podSecurityContext:
        runAsGroup: 10001
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile:
          type: RuntimeDefault
        # /var/log/pods 配下のログファイルが 0640 root:root であるため、
        # 読み取りには root グループへの所属が必要になる
        supplementalGroups:
          - 0
      presets:
        kubernetesAttributes:
          enabled: true
          extractAllPodAnnotations: true
          extractAllPodLabels: true
        logsCollection:
          enabled: true
          includeCollectorLogs: false
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
        privileged: false
        readOnlyRootFilesystem: true

resources:
  - ./resources/namespace.yaml
  - ./resources/secret.yaml
```

`logsCollection` preset の `storeCheckpoints` は設定しない。
既定値の `false` のままとする。有効にすると `/var/lib/otelcol` への書き込みが必要になり、`readOnlyRootFilesystem: true` と両立しない。

- [ ] **Step 3: ApplicationSet に登録する**

`k8s/system/argo-cd/resources/application-set-lily.yaml` の `# system` セクション、`mackerel-operator` のエントリの後に追加する。

```yaml
          - name: opentelemetry-collector
            namespace: opentelemetry-collector
            path: k8s/system/opentelemetry-collector
            project: system
```

- [ ] **Step 4: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

期待：`build-manifests` と `eslint` はエラーなし。kube-linter はベースラインとの diff が空である。
`kube-linter` が `run-as-non-root` や `privileged-container` を指摘する場合、`podSecurityContext` と `securityContext` の設定が Helm chart のどのキーに対応しているかを確認する。chart によってはコンテナ単位の securityContext のキー名が異なる。

- [ ] **Step 5: 生成されるマニフェストの securityContext を目視確認する**

```bash
mise exec -- kustomize build --enable-helm k8s/system/opentelemetry-collector \
  | python3 -c "
import sys, yaml
for doc in yaml.safe_load_all(sys.stdin):
    if doc and doc.get('kind') == 'DaemonSet':
        spec = doc['spec']['template']['spec']
        print('pod securityContext:', spec.get('securityContext'))
        for c in spec['containers']:
            print(f\"container {c['name']} securityContext:\", c.get('securityContext'))
"
```

期待：pod 側に `runAsNonRoot: True`、`runAsUser: 10001`、`supplementalGroups: [0]` が、container 側に `allowPrivilegeEscalation: False`、`capabilities: {'drop': ['ALL']}`、`readOnlyRootFilesystem: True`、`privileged: False` が出力される。

- [ ] **Step 6: コミット**

```bash
git add k8s/system/opentelemetry-collector k8s/system/argo-cd/resources/application-set-lily.yaml
git commit -F - <<'EOF'
feat(opentelemetry-collector): 非 root の DaemonSet で Pod ログを読む

Mackerel へのログ送信基盤の土台を用意する。まず debug exporter のみを
設定し、非 root で /var/log/pods を読めることを検証する。

ノード上のログファイルは 0640 root:root であるため、supplementalGroups
に root グループを付与することで uid 0 を使わずに読み取れる。

既存の設定は mode: deployment でありながら DaemonSet 前提の
logsCollection preset を有効にしており、そのままでは使えないため
全面的に書き換えた。ApplicationSet にも未登録だったため追加する。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 7: デプロイして非 root での読み取りを検証する**

ArgoCD の同期を待つ。

```bash
mise exec -- kubectl rollout status ds/otel-agent-opentelemetry-collector-agent \
  -n opentelemetry-collector --timeout=5m
```

DaemonSet の名前は chart のバージョンによって変わる。実際の名前を確認する。

```bash
mise exec -- kubectl get ds -n opentelemetry-collector
```

Pod が非 root で動いていることを確認する。

```bash
POD=$(mise exec -- kubectl get pod -n opentelemetry-collector -o name | head -1)
mise exec -- kubectl get "$POD" -n opentelemetry-collector \
  -o jsonpath='{.spec.securityContext}{"\n"}{.spec.containers[0].securityContext}{"\n"}'
```

期待：`runAsNonRoot: true`、`runAsUser: 10001` が含まれる。

ログを実際に読めていることを確認する。

```bash
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=50 | grep -E "LogsExporter|log records"
```

期待：`LogsExporter` の行に `#log records` が 0 より大きい値で出力される。

エラーが出る場合は次を確認する。

```bash
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=100 | grep -iE "permission denied|error"
```

`permission denied` が出る場合、`supplementalGroups: [0]` では不足している。
その場合は `podSecurityContext` を `runAsUser: 0` に変更し、`runAsNonRoot` を削除して再デプロイする（他の securityContext 項目は維持する）。設計文書の未決事項に結果を追記する。

---

## Task 4: ログ変換パイプラインの構築

ANSI エスケープの除去、severity の判定、サービス名の設定、オプトアウト判定、サンプリングを組み立てる。
このタスクでも exporter は `debug` のままとし、変換結果を目視で確認する。

**Files:**
- Modify: `k8s/system/opentelemetry-collector/kustomization.yaml`（`config` セクション）

**Interfaces:**
- Consumes: Task 3 で作成した `otel-agent` の Helm リリース
- Produces: リソース属性 `service.namespace`、`service.name`、ログレコード属性 `sample_priority`

- [ ] **Step 1: config セクションを書き換える**

`kustomization.yaml` の `valuesInline.config` を次の内容に置き換える。
`presets` と `securityContext` などの他のキーは Task 3 のまま変更しない。

```yaml
      config:
        exporters:
          debug:
            # 変換結果を目視で確認するため detailed にする。
            # Task 5 で Mackerel exporter に切り替える際に削除する。
            verbosity: detailed
        processors:
          # 除外対象を先に落とし、後続の変換コストを減らす
          filter/optout:
            error_mode: ignore
            logs:
              log_record:
                - 'resource.attributes["k8s.pod.annotation.mackerel.io/logs"] == "false"'
          probabilistic_sampler:
            # 初期値は 100%。発生源の是正により全量でも月 720 円に収まるため、
            # まず全量送信して実データを確認する。
            sampling_percentage: 100
            sampling_priority: sample_priority
          transform/sampling:
            error_mode: ignore
            log_statements:
              # WARN 以上は優先度 100 を付与し、サンプリング率に関わらず必ず通す
              - set(attributes["sample_priority"], 100)
                  where severity_number >= SEVERITY_NUMBER_WARN
          transform/service_name:
            error_mode: ignore
            log_statements:
              - set(resource.attributes["service.namespace"],
                    resource.attributes["k8s.namespace.name"])
              - set(resource.attributes["service.name"],
                    resource.attributes["k8s.deployment.name"])
                  where resource.attributes["k8s.deployment.name"] != nil
              - set(resource.attributes["service.name"],
                    resource.attributes["k8s.daemonset.name"])
                  where resource.attributes["service.name"] == nil
                    and resource.attributes["k8s.daemonset.name"] != nil
              - set(resource.attributes["service.name"],
                    resource.attributes["k8s.statefulset.name"])
                  where resource.attributes["service.name"] == nil
                    and resource.attributes["k8s.statefulset.name"] != nil
              - set(resource.attributes["service.name"],
                    resource.attributes["k8s.pod.name"])
                  where resource.attributes["service.name"] == nil
          transform/severity:
            error_mode: ignore
            log_statements:
              # zerolog の ConsoleWriter 形式は ANSI カラーエスケープを含む。
              # 先に除去しないと後続の正規表現がレベル表記に一致しない。
              - replace_pattern(body, "\\x1b\\[[0-9;]*m", "") where IsString(body)
              # JSON ログは level フィールドから判定する
              - set(severity_number, SEVERITY_NUMBER_ERROR)
                  where not IsString(body) and body["level"] == "error"
              - set(severity_number, SEVERITY_NUMBER_WARN)
                  where not IsString(body) and body["level"] == "warn"
              - set(severity_number, SEVERITY_NUMBER_INFO)
                  where not IsString(body) and body["level"] == "info"
              # テキストログは本文から推定する。zerolog の ERR / WRN 表記にも対応する
              - set(severity_number, SEVERITY_NUMBER_ERROR)
                  where IsString(body)
                    and IsMatch(body, "(?i)\\b(err|error|fatal|panic)\\b")
              - set(severity_number, SEVERITY_NUMBER_WARN)
                  where IsString(body)
                    and severity_number == SEVERITY_NUMBER_UNSPECIFIED
                    and IsMatch(body, "(?i)\\b(wrn|warn|warning)\\b")
        service:
          pipelines:
            logs:
              exporters:
                - debug
              processors:
                - filter/optout
                - transform/severity
                - transform/service_name
                - transform/sampling
                - probabilistic_sampler
```

`processors` の並びは ESLint により昇順に整列されるが、`service.pipelines.logs.processors` は配列であり**実行順序を持つ**。この配列の順序は変更してはならない。`pnpm eslint --fix` の実行後に、この配列の順序が保たれていることを必ず確認する。

- [ ] **Step 2: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

- [ ] **Step 3: processors 配列の順序が保たれていることを確認する**

```bash
grep -A8 "processors:" k8s/system/opentelemetry-collector/kustomization.yaml | grep -A7 "filter/optout"
```

期待：`filter/optout`, `transform/severity`, `transform/service_name`, `transform/sampling`, `probabilistic_sampler` の順で並んでいる。
順序が変わっている場合、`pnpm eslint --fix` が配列を並び替えている。`eslint.config.mjs` の `yml/sort-sequence-values` の設定を確認し、該当パスが対象外であることを確かめる。対象になっている場合はこの配列に `# eslint-disable-next-line yml/sort-sequence-values` を付けるのではなく、ユーザーに相談する。

- [ ] **Step 4: コミット**

```bash
git add k8s/system/opentelemetry-collector/kustomization.yaml
git commit -F - <<'EOF'
feat(opentelemetry-collector): ログ変換パイプラインを構築

ANSI エスケープの除去、severity の判定、サービス名の設定、
オプトアウト判定、サンプリングを組み立てる。

nebula のログは zerolog の ConsoleWriter 形式で ANSI カラーエスケープを
含むため、除去を最初に行う。順序を誤ると後続の正規表現が一致しない。

サンプリングは WARN 以上に優先度 100 を付与して常に通す。初期の
サンプリング率は 100% とし、実データを見てから調整する。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: 変換結果を確認する**

ArgoCD の同期を待つ。
`syncPolicy` は `selfHeal: true` であるため、`kubectl apply` による手動変更は数分で巻き戻される。
確認はコミット済みの状態に対して行う。

```bash
mise exec -- kubectl rollout status ds -n opentelemetry-collector --timeout=5m
POD=$(mise exec -- kubectl get pod -n opentelemetry-collector -o name | head -1)
```

サービス名と severity が設定されていることを確認する。

```bash
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=300 \
  | grep -E "service\.name|service\.namespace|SeverityNumber" | head -20
```

期待：`service.namespace` に namespace 名、`service.name` にワークロード名、`SeverityNumber` に `Info(9)` や `Error(17)` などが出力される。
`SeverityNumber` がすべて `Unspecified(0)` の場合、severity 判定が機能していない。`transform/severity` の OTTL 式を見直す。

ANSI エスケープが除去されていることを確認する。

```bash
COUNT=$(mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=300 \
  | grep -c $'\033\[' || true)
echo "ANSI エスケープを含む行: ${COUNT}"
```

期待：`0` である。
0 でない場合、`replace_pattern` の正規表現が RE2 で `\x1b` を解釈できていない。`\\x1b` を `\\u001b` に変えて再試行する。

nebula のログで実際に確認する。

```bash
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=500 \
  | grep -A3 'service.name: Str(backend)' | head -12
```

期待：`Body` に ANSI エスケープを含まない平文が出力され、`SeverityNumber` が設定されている。

---

## Task 5: Mackerel への送信を有効化

`debug` exporter を Mackerel の OTLP exporter に切り替える。

**Files:**
- Modify: `k8s/system/opentelemetry-collector/kustomization.yaml`（`exporters` と `extraEnvs`）

**Interfaces:**
- Consumes: Task 3 で作成した Secret `mackerel-api-key`（キー `apiKey`）、Task 4 で構築したパイプライン

- [ ] **Step 1: exporter と環境変数を追加する**

`valuesInline` に `extraEnvs` を追加し、`config.exporters` と `config.service.pipelines.logs.exporters` を書き換える。

```yaml
      config:
        exporters:
          otlphttp/mackerel:
            endpoint: https://otlp-vaxila.mackerelio.com
            headers:
              Mackerel-Api-Key: ${env:MACKEREL_APIKEY}
            sending_queue:
              batch:
                # Mackerel が受け付ける 1 リクエストの上限
                max_size: 3500000
                sizer: bytes
        # (processors は Task 4 のまま変更しない)
        service:
          pipelines:
            logs:
              exporters:
                - otlphttp/mackerel
              processors:
                - filter/optout
                - transform/severity
                - transform/service_name
                - transform/sampling
                - probabilistic_sampler
```

`valuesInline` の直下に `extraEnvs` を追加する（キーは昇順に整列されるため `config` の後、`image` の前になる）。

```yaml
      extraEnvs:
        - name: MACKEREL_APIKEY
          valueFrom:
            secretKeyRef:
              key: apiKey
              name: mackerel-api-key
```

`debug` exporter は削除する。

- [ ] **Step 2: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

`kube-linter` が `read-secret-from-env-var` を指摘しないことを確認する。このチェックは `.kube-linter.yaml` で除外済みである。

- [ ] **Step 3: processors 配列の順序を再確認する**

```bash
grep -A8 "processors:" k8s/system/opentelemetry-collector/kustomization.yaml | grep -A7 "filter/optout"
```

期待：Task 4 と同じ順序が保たれている。

- [ ] **Step 4: コミット**

```bash
git add k8s/system/opentelemetry-collector/kustomization.yaml
git commit -F - <<'EOF'
feat(opentelemetry-collector): Mackerel へのログ送信を有効化

debug exporter を otlphttp exporter に切り替え、Mackerel の OTLP
エンドポイントに送信する。API キーは 1Password Connect が配布する
Secret から環境変数で参照する。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: 送信されていることを確認する**

```bash
POD=$(mise exec -- kubectl get pod -n opentelemetry-collector -o name | head -1)
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=100 \
  | grep -iE "error|failed|401|403" || echo "送信エラーなし"
```

期待：`送信エラーなし` と表示される。
`401` や `403` が出る場合、Secret のキー名が `apiKey` であること、および API キーに Write 権限があることを確認する。

Collector 自身のメトリクスで送信数を確認する。

```bash
mise exec -- kubectl exec "$POD" -n opentelemetry-collector -- \
  wget -qO- http://localhost:8888/metrics 2>/dev/null \
  | grep -E "otelcol_exporter_sent_log_records_total|otelcol_exporter_send_failed_log_records_total"
```

イメージに `wget` がない場合は port-forward で取得する。

```bash
mise exec -- kubectl port-forward -n opentelemetry-collector "$POD" 8888:8888 &
sleep 3
curl -s http://localhost:8888/metrics | grep -E "otelcol_exporter_sent_log_records_total|otelcol_exporter_send_failed_log_records_total"
kill %1
```

期待：`sent` が 0 より大きく、`send_failed` が 0 である。

- [ ] **Step 6: Mackerel の画面でログを確認する**

Mackerel のログ画面を開き、次を目視で確認する。

- `service.namespace` ごとにサービスが分類されて表示される
- ログレベルでの絞り込みが機能する
- WARN 以上のログが届いている

- [ ] **Step 7: オプトアウトの動作を確認する**

既存のワークロードにアノテーションを付ける方法は使えない。
ArgoCD の `syncPolicy` が `selfHeal: true` であるため、`kubectl patch` による変更は数分で巻き戻される。

代わりに ArgoCD の管理外に検証用の Namespace と Deployment を作る。
ApplicationSet に登録されていない Namespace であれば、ArgoCD は干渉しない。

```bash
mise exec -- kubectl create namespace mackerel-optout-test
mise exec -- kubectl create deployment noisy \
  -n mackerel-optout-test \
  --image=busybox:1.37 \
  -- sh -c 'while true; do echo "optout test $(date)"; sleep 2; done'
mise exec -- kubectl rollout status deploy/noisy -n mackerel-optout-test --timeout=2m
```

まず Mackerel の画面で `mackerel-optout-test / noisy` のログが届くことを確認する。
届いていれば、アノテーションを付けて止まることを確認する。

```bash
mise exec -- kubectl patch deploy noisy -n mackerel-optout-test \
  --type=merge \
  -p '{"spec":{"template":{"metadata":{"annotations":{"mackerel.io/logs":"false"}}}}}'
mise exec -- kubectl rollout status deploy/noisy -n mackerel-optout-test --timeout=2m
```

数分待ってから Mackerel の画面で新しいログが止まっていることを確認する。

確認後、検証用リソースを削除する。

```bash
mise exec -- kubectl delete namespace mackerel-optout-test
```

この検証は一時的なもので、リポジトリのマニフェストは変更しない。

---

## Task 6: Kubernetes Events の収集

`kubernetesEvents` preset は Deployment を前提とするため、2 つ目の Helm リリースとして追加する。

**Files:**
- Modify: `k8s/system/opentelemetry-collector/kustomization.yaml`（`helmCharts` に 2 つ目のリリースを追加）

**Interfaces:**
- Consumes: Task 3 で作成した Secret `mackerel-api-key`
- Produces: Helm リリース `otel-cluster`（Deployment）

- [ ] **Step 1: 2 つ目の Helm リリースを追加する**

`helmCharts` の配列に、既存の `otel-agent` の後に追加する。

```yaml
  - name: opentelemetry-collector
    releaseName: otel-cluster
    namespace: opentelemetry-collector
    version: 0.159.0
    repo: https://open-telemetry.github.io/opentelemetry-helm-charts
    valuesInline:
      config:
        exporters:
          otlphttp/mackerel:
            endpoint: https://otlp-vaxila.mackerelio.com
            headers:
              Mackerel-Api-Key: ${env:MACKEREL_APIKEY}
            sending_queue:
              batch:
                max_size: 3500000
                sizer: bytes
        processors:
          transform/service_name:
            error_mode: ignore
            log_statements:
              # クラスタ全体のイベントであり、特定の namespace に属さない
              - set(resource.attributes["service.namespace"], "lily")
              - set(resource.attributes["service.name"], "kubernetes-events")
        service:
          pipelines:
            logs:
              exporters:
                - otlphttp/mackerel
              processors:
                - transform/service_name
      extraEnvs:
        - name: MACKEREL_APIKEY
          valueFrom:
            secretKeyRef:
              key: apiKey
              name: mackerel-api-key
      image:
        repository: otel/opentelemetry-collector-k8s
      mode: deployment
      podSecurityContext:
        runAsGroup: 10001
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile:
          type: RuntimeDefault
      presets:
        kubernetesEvents:
          enabled: true
      replicaCount: 1
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop:
            - ALL
        privileged: false
        readOnlyRootFilesystem: true
```

Kubernetes API のみを参照しホストのファイルを読まないため、`supplementalGroups` は設定しない。

- [ ] **Step 2: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

- [ ] **Step 3: 2 つのリリースが別々の名前で生成されることを確認する**

```bash
mise exec -- kustomize build --enable-helm k8s/system/opentelemetry-collector \
  | grep -E "^  name: otel-(agent|cluster)" | sort -u
```

期待：`otel-agent` と `otel-cluster` の両方を含む名前が出力される。
名前が衝突している場合、`releaseName` が正しく反映されていない。

- [ ] **Step 4: コミット**

```bash
git add k8s/system/opentelemetry-collector/kustomization.yaml
git commit -F - <<'EOF'
feat(opentelemetry-collector): Kubernetes Events の収集を追加

kubernetesEvents preset は Deployment を前提とするため、
DaemonSet とは別の Helm リリースとして追加する。

Kubernetes API のみを参照しホストのファイルを読まないため、
supplementalGroups は付与せず、より厳格な securityContext を適用する。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: イベントが届いていることを確認する**

```bash
mise exec -- kubectl get deploy -n opentelemetry-collector
POD=$(mise exec -- kubectl get pod -n opentelemetry-collector -l app.kubernetes.io/instance=otel-cluster -o name | head -1)
mise exec -- kubectl logs "$POD" -n opentelemetry-collector --tail=50 \
  | grep -iE "error|failed" || echo "エラーなし"
```

Mackerel の画面で `lily / kubernetes-events` のサービスが表示され、Pod の起動やスケジューリングのイベントが届いていることを確認する。

---

## Task 7: journald の橋渡し

Alloy が既に読み取っている journald のログを、OTLP で Collector に転送する。
Alloy から Mackerel には直接送らない。送信は Collector に一元化する。

**Files:**
- Modify: `k8s/apps/grafana-alloy/config/config.alloy`
- Modify: `k8s/system/opentelemetry-collector/kustomization.yaml`（`otel-agent` に `otlp` receiver を追加）

**Interfaces:**
- Consumes: Task 5 で構築した `otel-agent` の logs パイプライン
- Produces: `otel-agent` の OTLP receiver（gRPC :4317）

- [ ] **Step 1: Collector に OTLP receiver を追加する**

`otel-agent` の `config` に `receivers` と、journald 専用のパイプラインを追加する。
Pod ログとは別のパイプラインにする理由は、journald には ANSI エスケープや Kubernetes のメタデータが存在せず、Pod ログ向けの変換が不要なためである。

`config` の `receivers` セクションを追加する。

```yaml
          receivers:
            otlp:
              protocols:
                grpc:
                  endpoint: 0.0.0.0:4317
```

`processors` に journald 用のサービス名設定を追加する。

```yaml
          transform/journald_service_name:
            error_mode: ignore
            log_statements:
              # ノードの systemd ログはクラスタ単位で扱う
              - set(resource.attributes["service.namespace"], "lily")
              - set(resource.attributes["service.name"], "systemd")
```

`service.pipelines` に journald 用のパイプラインを追加する。
既存の `logs` パイプラインは変更しない。

```yaml
          service:
            pipelines:
              logs:
                exporters:
                  - otlphttp/mackerel
                processors:
                  - filter/optout
                  - transform/severity
                  - transform/service_name
                  - transform/sampling
                  - probabilistic_sampler
              logs/journald:
                exporters:
                  - otlphttp/mackerel
                processors:
                  - transform/journald_service_name
                receivers:
                  - otlp
```

`logsCollection` preset が生成する `logs` パイプラインの receiver は preset が管理するため、明示的に書かない。

- [ ] **Step 2: Alloy の config に OTLP 転送を追加する**

`k8s/apps/grafana-alloy/config/config.alloy` の末尾に追加する。

```river
// journald のログを OpenTelemetry Collector に転送する。
// Collector の公式イメージは distroless で journalctl を含まないため、
// journald の読み取りだけを Alloy が担い、Mackerel への送信は Collector が行う。
otelcol.receiver.loki "journald" {
	output {
		logs = [otelcol.exporter.otlp.collector.input]
	}
}

otelcol.exporter.otlp "collector" {
	client {
		endpoint = "otel-agent-opentelemetry-collector-agent.opentelemetry-collector:4317"

		tls {
			insecure = true
		}
	}
}
```

エンドポイントの Service 名は実際に生成されたものに合わせる。

```bash
mise exec -- kubectl get svc -n opentelemetry-collector
```

既存の `loki.source.journal` の `forward_to` に転送先を追加する。
`loki.write.default.receiver` は残し、Loki への送信を維持する。

```river
loki.source.journal "node_systemd_journal" {
	forward_to    = [
		loki.write.default.receiver,
		otelcol.receiver.loki.journald.receiver,
	]
	relabel_rules = loki.relabel.node_systemd_journal.rules
	labels        = {component = "loki.source.journal"}
}
```

- [ ] **Step 3: ビルドと lint を通す**

```bash
mise exec -- go run ./cmd/build-manifests
mise exec -- pnpm eslint --fix
mise exec -- pnpm eslint
mise exec -- kube-linter lint --config .kube-linter.yaml ./k8s
```

kube-linter は既存の 633 件を出力し exit code 1 で終了する。
「全タスク共通の検証コマンド」節の手順でベースラインと diff を取り、
**新規の指摘が増えていないこと**を確認する。

`config.alloy` は `k8s/**/config/**` に該当するため `yml/file-extension` の対象外である。River 形式のファイルは ESLint の検査対象にならない。

- [ ] **Step 4: コミット**

```bash
git add k8s/apps/grafana-alloy/config/config.alloy k8s/system/opentelemetry-collector/kustomization.yaml
git commit -F - <<'EOF'
feat(grafana-alloy): journald のログを Collector に橋渡し

OpenTelemetry の journald receiver は journalctl バイナリを実行する
実装であり、公式イメージ otel/opentelemetry-collector-k8s は distroless
で sh すら含まないため動作しない。

Alloy の loki.source.journal は libsystemd を直接呼ぶ自前実装であり
既に稼働しているため、journald の読み取りだけを Alloy に任せ、
OTLP で Collector に渡す。Mackerel への送信、severity の付与、
サンプリングはすべて Collector 側で行う。

journald には ANSI エスケープも Kubernetes のメタデータも存在しない
ため、Pod ログとは別のパイプラインで処理する。

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
```

- [ ] **Step 5: journald のログが Mackerel に届くことを確認する**

Alloy の再起動を待つ。

```bash
mise exec -- kubectl rollout status ds/alloy -n grafana-alloy --timeout=5m
```

Alloy 側でエラーが出ていないことを確認する。

```bash
POD=$(mise exec -- kubectl get pod -n grafana-alloy -o name | head -1)
mise exec -- kubectl logs "$POD" -n grafana-alloy -c alloy --tail=50 \
  | grep -iE "error|failed" || echo "Alloy にエラーなし"
```

Loki への送信が継続していることを確認する。

```bash
mise exec -- kubectl get --raw \
  "/api/v1/namespaces/grafana-loki/services/loki:3100/proxy/loki/api/v1/query?query=sum(bytes_over_time(%7Bcomponent%3D%22loki.source.journal%22%7D%5B5m%5D))"
```

期待：0 より大きい値が返る。

Mackerel の画面で `lily / systemd` のサービスが表示され、`kubelet` や `crio` のログが届いていることを確認する。

---

## 完了後の作業

- [ ] **設計文書の未決事項を更新する**

`docs/superpowers/specs/2026-08-01_mackerel-log-ingestion.md` の「未決事項とリスク」節を、実際の検証結果で更新する。特に次の 3 点を確定させる。

- `supplementalGroups: [0]` で Pod ログを読めたか
- nebula のアプリケーションが `LOG_LEVEL` を参照したか
- ANSI エスケープ除去の正規表現が実データで機能したか

- [ ] **実際の送信量を計測し、サンプリング率を判断する**

発生源の是正後、1 日以上経過してから Loki の受信量を再計測する。

```bash
mise exec -- kubectl get --raw \
  "/api/v1/namespaces/grafana-loki/services/loki:3100/proxy/metrics" \
  | grep "^loki_distributor_bytes_received_total"
```

想定は 0.68 GB/日である。
大きく上回る場合は `probabilistic_sampler` の `sampling_percentage` を下げる。
その際、trace ID を持たないログのハッシュ種として `attribute_source: record` と `from_attribute` の指定が必要になる。種の選択肢は設計文書の「サンプリング」節を参照する。

- [ ] **PR を作成する**

未完事項が残っている場合は Draft、すべて検証済みなら通常の PR とする。
本文には次のセクションを含める。

- **概要**：Mackerel へのログ送信基盤を追加したこと
- **実測データ**：是正前後のログ量の比較（実際に計測した値を記載する）
- **検証結果**：各タスクの検証ステップの結果。Mackerel の画面はスクリーンショットを添付する
- **動物界における比擬**：変更点を動物の生態に擬した解説

スクリーンショットの添付には `github-image-upload` スキル（`gh image upload`）を使う。

```bash
gh pr create \
  --title "feat: Mackerel へのログ送信基盤を追加" \
  --body-file <(cat <<'EOF'
## 概要

lily クラスタの Pod ログ、journald、Kubernetes Events を
OpenTelemetry Collector 経由で Mackerel に送る基盤を追加する。

設計は `docs/superpowers/specs/2026-08-01_mackerel-log-ingestion.md` にある。

## 実測データ

（実際に計測した是正前後の値を記載する）

## 検証結果

（各タスクの検証ステップの結果を記載する）

## 動物界における比擬

（変更点を動物の生態に擬して解説する）
EOF
)
gh pr edit --add-assignee SlashNephy
```
