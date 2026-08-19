# lily の Mahiron 5 系移行 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** lily の `mahiron` namespace を Mahiron 4 系から 5 系 (`ghcr.io/starrybluesky/mahiron5-custom`) に移行する。

**Architecture:** 変更は 2 層に分かれる。リポジトリ側は `k8s/apps/mahiron/lily/resources/deployment.yaml` 1 ファイルのみ (image / args / mount パス / env)。lily ホスト側は `/mnt/local/mahiron5/config/` に設定 4 ファイルを新規作成する。既存の `/mnt/local/mahiron/` には一切触れないため、切り戻しは Deployment の revert だけで完結する。

**Tech Stack:** Kubernetes (kustomize), Argo CD (automated sync + selfHeal), Traefik IngressRoute, hostPath ボリューム。検証は `go run ./cmd/build-manifests` と `kube-linter`。

## Global Constraints

- 設計文書は [docs/superpowers/specs/2026-08-19_mahiron5-migration.md](../specs/2026-08-19_mahiron5-migration.md)。差異が出た場合は設計文書が正
- **このリポジトリは公開されている。** 相互共有先のホスト名、Basic 認証の資格情報、Discord ユーザー ID、カスタムイメージの内部構造を、コミット・PR・本計画・スクリーンショットのいずれにも含めない
- ホスト側の設定ファイル (`/mnt/local/mahiron5/config/`) はリポジトリ管理外である。リポジトリにコピーしない
- lily はワークステーションとは別ホストである。ノード上の操作は必ず `ssh lily` を経由する
- Argo CD は `automated` + `selfHeal` で同期する。**master にマージした時点で即座にロールアウトが始まる。** ホスト側の設定が揃う前にマージしてはならない
- `/mnt/local/mahiron/` (4 系のデータと設定) は移行作業中も一切変更しない。切り戻しの土台である
- コミットメッセージは Conventional Commits 形式、`Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>` を付ける
- 作業ブランチは `feat/mahiron5-migration` (作成済み)

---

## File Structure

| ファイル | 層 | 責務 |
| --- | --- | --- |
| `k8s/apps/mahiron/lily/resources/deployment.yaml` | リポジトリ | Pod 定義。image / args / env / hostPath マウント |
| `/mnt/local/mahiron5/config/server.yml` | lily ホスト | 待ち受けアドレス、DB パス、ログレベル、ジョブスケジュール |
| `/mnt/local/mahiron5/config/tuners.yml` | lily ホスト | ローカルチューナー 16 本の定義 |
| `/mnt/local/mahiron5/config/remotes.yml` | lily ホスト | Mirakurun 互換サーバーへの接続情報 (名前 / URL / Basic 認証) |
| `/mnt/local/mahiron5/config/channels.yml` | lily ホスト | チャンネル 78 件。リモート取り込み分は `routes` で経路を定義 |

タスクは「ホスト側設定の作成 → 使い捨て Pod での検証 → リポジトリ側の変更 → 本番切替 → 証跡」の順に進む。
この順序は Argo CD の自動同期を前提としており、入れ替えると本番が壊れた設定で起動する。

---

### Task 1: ホスト側の設定ディレクトリと `server.yml` / `tuners.yml` を作る

**Files:**
- Create: `/mnt/local/mahiron5/config/server.yml` (lily ホスト)
- Create: `/mnt/local/mahiron5/config/tuners.yml` (lily ホスト)
- Create: `/mnt/local/mahiron5/data/` (lily ホスト、空ディレクトリ)

**Interfaces:**
- Consumes: 現行の `/mnt/local/mahiron/config/tuners.yml` (ローカルチューナー定義の写し元)
- Produces: `/mnt/local/mahiron5/config/` — Task 2 以降のすべてのタスクがこのディレクトリを参照する

- [ ] **Step 1: ディレクトリを作る**

現行の設定ディレクトリと同じ所有者 (`spica:spica`) に揃える。

```bash
ssh lily 'mkdir -p /mnt/local/mahiron5/config /mnt/local/mahiron5/data && ls -ld /mnt/local/mahiron5/config /mnt/local/mahiron5/data'
```

Expected: 2 行とも `drwxr-xr-x` で表示される。

- [ ] **Step 2: `server.yml` を書く**

`addresses` を省略すると `localhost:40772` に束縛され Pod の外から到達できない。
`databasePath` と `dataBroadcastCachePath` を省略すると作業ディレクトリ配下の相対パスになり、コンテナの揮発領域に書かれる。
どちらも明示が必須である。

```bash
ssh lily 'cat > /mnt/local/mahiron5/config/server.yml <<'"'"'EOF'"'"'
addresses:
  - http: :40772

logLevel: info

databasePath: /var/db/mahiron/mahiron.db
dataBroadcastCachePath: /var/db/mahiron/data-broadcast-cache.db

jobs:
  - key: service-updater
    schedule: "5 6 * * *"
  - key: epg-gatherer
    schedule: "20,50 * * * *"
  - key: logo-gatherer
    schedule: "5 3 * * *"
EOF'
```

- [ ] **Step 3: `tuners.yml` を書く**

現行ファイルからローカルチューナー 16 本 (`PX-Q3PE4_*` 8 本と `PX-MLT8PE_*` 8 本) だけを写す。
コマンドテンプレートの `<channel>` は 5 系でもそのまま有効なので変更しない。
リモート取り込み用のチューナー定義とコメントアウト済みの定義は、`remotes.yml` と `routes` に置き換わるため写さない。

現行ファイルの先頭 16 定義がちょうどローカル分にあたる。境界を目視で確認してから切り出す。

```bash
ssh lily 'grep -n "^- name:" /mnt/local/mahiron/config/tuners.yml | head -20'
```

Expected: 1〜16 番目がローカルのチューナー (`PX-` で始まる名前)、
17 番目以降がリモート取り込み用の定義であることを確認する。

```bash
ssh lily 'awk "/mirakurun-client/{exit} /^- name:/ && \$0 !~ /^- name: PX-/{exit} {print}" /mnt/local/mahiron/config/tuners.yml > /mnt/local/mahiron5/config/tuners.yml && grep -c "^- name:" /mnt/local/mahiron5/config/tuners.yml'
```

Expected: `16`

- [ ] **Step 4: リモート取り込みの定義が混入していないことを確認する**

```bash
ssh lily 'grep -c "mirakurun-client" /mnt/local/mahiron5/config/tuners.yml || echo 0'
```

Expected: `0`

- [ ] **Step 5: 現行の設定が無傷であることを確認する**

```bash
ssh lily 'ls -la /mnt/local/mahiron/config/ && md5sum /mnt/local/mahiron/config/tuners.yml'
```

Expected: 4 ファイル (`channels.yml` / `server.yml` / `services.yml` / `tuners.yml`) が残っている。
この md5 は Task 7 の切り戻し確認で再度照合するため記録しておく。

- [ ] **Step 6: コミット**

このタスクはホスト側のみの変更であり、リポジトリに差分は出ない。コミットは不要。

---

### Task 2: `remotes.yml` と `channels.yml` を作る

**Files:**
- Create: `/mnt/local/mahiron5/config/remotes.yml` (lily ホスト)
- Create: `/mnt/local/mahiron5/config/channels.yml` (lily ホスト)

**Interfaces:**
- Consumes: 現行の `/mnt/local/mahiron/config/channels.yml` と `/mnt/local/mahiron/config/services.yml`
- Produces: `routes` を持つ `channels.yml` — Task 3 の設定パース検証と Task 5 の本番切替が参照する

- [ ] **Step 1: リモートの対応表を現行設定から起こす**

現行の `services.yml` はリモート名ごとに `base_uri` と `basic` (`user:password` 形式) を持つ。
現行の `channels.yml` の `servicesCommand` は、チャンネル種別ごとにどのリモートを使うかを示す。
この 2 つを突き合わせて対応表を作る。

```bash
ssh lily 'awk "/type: EXT/{t=\$2} /servicesCommand:/{for(i=1;i<=NF;i++) if(\$i ~ /^[a-z0-9.,]+\$/ && \$i !~ /mirakurun-client|--timeout|^5\$/) {print t, \$i; break}}" /mnt/local/mahiron/config/channels.yml | sort | uniq -c'
```

Expected: 種別ごとにリモート名 (EXT2 と EXT3 はカンマ区切りの複数) が並ぶ。
カンマ区切りは優先順位付きのフォールバックであり、`routes` の `priority` に写す。

- [ ] **Step 2: `remotes.yml` を書く**

`services.yml` の各エントリを次の形に変換する。
`base_uri` はスキーム抜きの `host/path` 形式なので、`scheme` が明示されていなければ `https` を補い、末尾を `/api` に揃える。
`basic` の `user:password` を `username` と `password` に分ける。

```yaml
- name: <services.yml のキーをそのまま>
  url: <scheme>://<base_uri>
  basicAuth:
    username: <basic の : より前>
    password: <basic の : より後>
```

Basic 認証を持たないリモートは `basicAuth` ごと省略する。

bbc を指すリモートは稼働していないが、`channels.yml` 側で無効化した経路からも名前解決される。
定義自体は残す。

**このファイルには資格情報が入る。リポジトリにコピーしない。**

```bash
ssh lily 'chmod 600 /mnt/local/mahiron5/config/remotes.yml && ls -l /mnt/local/mahiron5/config/remotes.yml'
```

Expected: `-rw-------`

- [ ] **Step 3: `channels.yml` の GR / BS / CS 部分を写す**

`servicesCommand` / `programsCommand` を持たない 47 件はそのまま使える。

```bash
ssh lily 'cp /mnt/local/mahiron/config/channels.yml /mnt/local/mahiron5/config/channels.yml && grep -c "^- name:" /mnt/local/mahiron5/config/channels.yml'
```

Expected: `78`

- [ ] **Step 4: EXT の各エントリを `routes` に書き換える**

`servicesCommand` と `programsCommand` の 2 行を削除し、`routes` を追加する。
5 系の設定読み込みは未知のキーをエラーとして扱うため、削除漏れは起動失敗として現れる。

単一経路の場合 (EXT1 / EXT4 / EXT5 / EXT7):

```yaml
- name: <現行のまま>
  type: EXT1
  channel: "47"
  routes:
    - id: <リモート名>
      remote: <リモート名>
      type: EXT1        # リモート側のチャンネル種別
      channel: "47"
      priority: 10
```

`type` は 2 か所に現れる。外側は lily が公開する種別 (現行のまま維持)、
`routes` の中はリモート側の種別である。両者は一致しないことがある。
現行の `servicesCommand` に含まれる `channel.type=` の値がリモート側の種別にあたる。

複数経路の場合 (EXT2 / EXT3)、`priority` の小さい順に試される。
現行のカンマ区切りの並び順をそのまま優先順位とする:

```yaml
- name: <現行のまま>
  type: EXT2
  channel: "16"
  routes:
    - id: <リモート名 1>
      remote: <リモート名 1>
      type: GR
      channel: "16"
      isDisabled: true    # bbc を指す経路のみ
      priority: 10
    - id: <リモート名 2>
      remote: <リモート名 2>
      type: GR
      channel: "16"
      priority: 20
    - id: <リモート名 3>
      remote: <リモート名 3>
      type: GR
      channel: "16"
      priority: 30
```

- [ ] **Step 5: EXT6 を無効化する**

EXT6 の 2 件は bbc が唯一の供給元であり、bbc は稼働していない。
チャンネル定義は残し、`isDisabled: true` を付けて `routes` は与えない。

```yaml
- name: <現行のまま>
  type: EXT6
  channel: "<現行のまま>"
  isDisabled: true
```

- [ ] **Step 6: EXT4 の経路を定義する**

EXT4 の 3 件は 4 系ではストリーム経路が存在しなかった (リモート取り込み用チューナーが未定義だった)。
他の単一経路の種別と同じ形で `routes` を定義する。設計文書で合意済みの挙動変化である。

- [ ] **Step 7: 書き換え漏れがないことを確認する**

```bash
ssh lily 'grep -c "servicesCommand\|programsCommand" /mnt/local/mahiron5/config/channels.yml || echo 0'
```

Expected: `0`

```bash
ssh lily 'grep -c "^- name:" /mnt/local/mahiron5/config/channels.yml; grep -c "routes:" /mnt/local/mahiron5/config/channels.yml; grep -c "isDisabled: true" /mnt/local/mahiron5/config/channels.yml'
```

Expected: 順に `78` / `29` / `7`
(`routes` は EXT1 7 + EXT2 5 + EXT3 1 + EXT4 3 + EXT5 3 + EXT7 10 = 29 件、
`isDisabled: true` は EXT6 2 件 + EXT2 の bbc 経路 5 件 = 7 件。
実際の件数は Step 1 の出力と突き合わせて確定させる)

- [ ] **Step 8: コミット**

ホスト側のみの変更のため、リポジトリに差分は出ない。コミットは不要。

---

### Task 3: 使い捨て Pod で設定のパースを検証する

**Files:**
- Create: `<scratchpad>/mahiron5-parse-check.yaml` (一時ファイル、リポジトリ外)
- Create: `/mnt/local/mahiron5/config-check/` (lily ホスト、検証後に削除)

**Interfaces:**
- Consumes: Task 1 と Task 2 が作った `/mnt/local/mahiron5/config/`
- Produces: 設定が読めることの確証。Task 5 の本番切替はこの確認を前提にする

- [ ] **Step 1: 検証用の設定を用意する**

本番のチューナーを奪わないため、ローカルチャンネルをすべて無効化した写しを作る。
これをしないと起動直後のサービススキャンが `/dev/px4video*` を掴みに行き、稼働中の 4 系と競合する。

```bash
ssh lily 'mkdir -p /mnt/local/mahiron5/config-check && cp /mnt/local/mahiron5/config/*.yml /mnt/local/mahiron5/config-check/'
```

既存の `isDisabled` 行を先に除去してから付与する。同じキーが 2 回現れると読み込みが落ちるためである。

```bash
ssh lily 'grep -v "^  isDisabled:" /mnt/local/mahiron5/config/channels.yml | awk "/^- name:/{print; print \"  isDisabled: true\"; next} {print}" > /mnt/local/mahiron5/config-check/channels.yml && grep -c "^  isDisabled: true" /mnt/local/mahiron5/config-check/channels.yml'
```

Expected: `78`

検証用の `server.yml` は待ち受けポートだけ変える。

```bash
ssh lily 'sed -i "s/http: :40772/http: :40773/" /mnt/local/mahiron5/config-check/server.yml && grep http: /mnt/local/mahiron5/config-check/server.yml'
```

Expected: `  - http: :40773`

- [ ] **Step 2: 検証用 Pod のマニフェストを書く**

`hostNetwork` を付けず、デバイスもマウントしない。設定の読み込みだけを見る。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mahiron5-parse-check
  namespace: mahiron
spec:
  restartPolicy: Never
  imagePullSecrets:
    - name: ghcr-io-credentials
  containers:
    - name: app
      image: ghcr.io/starrybluesky/mahiron5-custom:master
      imagePullPolicy: Always
      args:
        - -config-dir
        - /etc/mahiron
      env:
        - name: TZ
          value: Asia/Tokyo
      volumeMounts:
        - name: config
          mountPath: /etc/mahiron
          readOnly: true
        - name: data
          mountPath: /var/db/mahiron
  volumes:
    - name: config
      hostPath:
        path: /mnt/local/mahiron5/config-check
        type: Directory
    - name: data
      hostPath:
        path: /mnt/local/mahiron5/data-check
        type: DirectoryOrCreate
```

- [ ] **Step 3: 起動してログを見る**

```bash
kubectl apply -f <scratchpad>/mahiron5-parse-check.yaml
```

```bash
kubectl logs -n mahiron mahiron5-parse-check --follow --tail=100
```

Expected: `failed to load config` が出ないこと。
`opening database` → `database migrations completed` → `starting HTTP server` の順に進むこと。
設定に問題があれば `failed to load config` とエラー内容が 1 行で出る。

- [ ] **Step 4: リモート接続が成立することを確認する**

```bash
kubectl exec -n mahiron mahiron5-parse-check -- curl -fsS http://localhost:40773/api/version
```

Expected: JSON が返り、`server` フィールドが `mahiron` であること。

- [ ] **Step 5: 検証用リソースを片付ける**

```bash
kubectl delete pod -n mahiron mahiron5-parse-check
```

```bash
ssh lily 'rm -rf /mnt/local/mahiron5/config-check /mnt/local/mahiron5/data-check && ls /mnt/local/mahiron5/'
```

Expected: `config` と `data` のみが残る。

- [ ] **Step 6: コミット**

一時ファイルはリポジトリ外に置くため、コミットは不要。

---

### Task 4: Deployment を 5 系向けに書き換える

**Files:**
- Modify: `k8s/apps/mahiron/lily/resources/deployment.yaml`

**Interfaces:**
- Consumes: Task 3 で検証済みの `/mnt/local/mahiron5/config/`
- Produces: master にマージすると Argo CD が同期する Pod 定義

- [ ] **Step 1: イメージの digest を解決する**

イメージは非公開のため匿名では引けない。クラスタの pull secret を使う Pod を一度起動し、
`imageID` から digest を読む。

```bash
kubectl run mahiron5-digest -n mahiron --restart=Never --image=ghcr.io/starrybluesky/mahiron5-custom:master --overrides='{"spec":{"imagePullSecrets":[{"name":"ghcr-io-credentials"}],"containers":[{"name":"mahiron5-digest","image":"ghcr.io/starrybluesky/mahiron5-custom:master","imagePullPolicy":"Always","command":["true"]}]}}'
```

```bash
kubectl get pod -n mahiron mahiron5-digest -o jsonpath='{.status.containerStatuses[0].imageID}'; echo
```

Expected: `ghcr.io/starrybluesky/mahiron5-custom@sha256:<64 桁>` が返る。

```bash
kubectl delete pod -n mahiron mahiron5-digest
```

- [ ] **Step 2: `deployment.yaml` を書き換える**

`k8s/apps/mahiron/lily/resources/deployment.yaml` の `containers[0]` を次の形にする。
`args` の追加は、イメージが既定で参照する設定ディレクトリが `/etc/mahiron` ではないためである。
`EXTERNAL_JSON_PATH` は 4 系のリモート取り込みに使っていた環境変数で、`remotes.yml` への移行により不要になる。

```yaml
      containers:
        - name: app
          image: ghcr.io/starrybluesky/mahiron5-custom:master@sha256:<Step 1 の digest>
          args:
            - -config-dir
            - /etc/mahiron
          env:
            - name: TZ
              value: Asia/Tokyo
          ports:
            - containerPort: 40772
          volumeMounts:
            - name: data
              mountPath: /var/db/mahiron
            - name: config
              mountPath: /etc/mahiron
              readOnly: true
            - name: dev-px4video0
              mountPath: /dev/px4video0
```

`dev-px4video0` 以降 16 個のデバイスマウント、`securityContext`、`hostNetwork`、
`imagePullSecrets`、`restartPolicy` は現行のまま変更しない。

- [ ] **Step 3: hostPath を新ディレクトリに向ける**

同ファイルの `volumes` のうち `data` と `config` を書き換え、`check-services` を削除する。
`check-services` は 4 系時代の名残で、マウント先のディレクトリは空のまま使われていない。

```yaml
      volumes:
        - name: data
          hostPath:
            path: /mnt/local/mahiron5/data
            type: DirectoryOrCreate
        - name: config
          hostPath:
            path: /mnt/local/mahiron5/config
            type: Directory
```

`volumeMounts` 側の `check-services` (`mountPath: /tmp/mahiron-check-services`) も併せて削除する。

- [ ] **Step 4: kustomize でビルドが通ることを確認する**

```bash
go run ./cmd/build-manifests
```

Expected: エラーなく終了する。

- [ ] **Step 5: 生成結果を目視で確認する**

```bash
kustomize build k8s/apps/mahiron/lily | grep -A6 "image: ghcr.io/starrybluesky/mahiron5-custom"
```

Expected: `args` に `-config-dir` と `/etc/mahiron` が並び、`EXTERNAL_JSON_PATH` が現れない。

```bash
kustomize build k8s/apps/mahiron/lily | grep -c "mahiron5"
```

Expected: `3` (image 1 + hostPath 2)

- [ ] **Step 6: kube-linter を通す**

```bash
kube-linter lint --config .kube-linter.yaml ./k8s/apps/mahiron
```

Expected: 現行と同じ指摘のみ。新規の指摘が出た場合は、抑制せずに内容を確認する。

- [ ] **Step 7: コミット**

```bash
git add k8s/apps/mahiron/lily/resources/deployment.yaml
git commit -m "$(cat <<'EOF'
feat(mahiron): lily の Mahiron を 5 系に移行する

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: 本番に切り替えて確認する

**Files:**
- Modify: なし (Argo CD による同期)

**Interfaces:**
- Consumes: Task 4 のコミット
- Produces: 稼働中の 5 系。Task 6 の証跡はここで取得する

- [ ] **Step 1: 切替前の値を記録する**

移行後に件数を突き合わせるため、先に取っておく。

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/channels | jq length
```

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/services | jq length
```

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/version
```

Expected: 3 つの出力を記録する。移行後の比較対象になる。

- [ ] **Step 2: PR を作り、マージ前にユーザーの承認を得る**

Argo CD は `automated` + `selfHeal` で同期するため、**master へのマージがそのまま本番のロールアウトになる**。
プランの承認とマージの承認は別である。
PR を作ったら、マージしてよいかをユーザーに明示的に確認し、承認を得るまでマージしない。

```bash
git push -u origin feat/mahiron5-migration
```

```bash
gh pr create --title "feat(mahiron): lily の Mahiron を 5 系に移行する" --body-file <本文>
```

PR 作成後、自分を Assign し、マージ可否を確認する。
コンフリクトがある場合は解消する。

**マージすると Argo CD が即座に同期する。** Task 1〜3 が完了していることを再確認してからマージする。

- [ ] **Step 3: ロールアウトを見届ける**

```bash
kubectl rollout status -n mahiron deploy/deployment --timeout=300s
```

Expected: `deployment "deployment" successfully rolled out`

- [ ] **Step 4: 起動ログを確認する**

```bash
kubectl logs -n mahiron deploy/deployment --tail=200
```

Expected: `failed to load config` が出ない。`starting HTTP server` が出る。

- [ ] **Step 5: API の疎通を確認する**

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/version
```

Expected: `server` フィールドが `mahiron`、バージョンが 5 系。

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/status | head -40
```

- [ ] **Step 6: チャンネルとサービスの件数を突き合わせる**

サービススキャンと EPG 取得は初回起動でやり直すため、`/api/services` が揃うまで時間がかかる。
数分待ってから確認する。

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/channels | jq length
```

Expected: Step 1 で記録した値と一致 (EXT6 の 2 件を無効化したため 2 件少なくなる可能性がある。
差分が出た場合は EXT6 由来であることを `jq` で確認する)

```bash
kubectl exec -n mahiron deploy/deployment -- curl -fsS http://localhost:40772/api/services | jq '[.[] | .channel.type] | group_by(.) | map({type: .[0], count: length})'
```

Expected: EXT1 / EXT2 / EXT3 / EXT4 / EXT5 / EXT7 のすべてにサービスが存在する。
EXT4 は 4 系では取得できていた種別であり、ここで欠けていればリモート経路の設定ミスである。

- [ ] **Step 7: ストリームの疎通を確認する**

ローカルチューナー経由 (GR) とリモート経路 (EXT7) を 1 本ずつ引く。

```bash
kubectl exec -n mahiron deploy/deployment -- bash -c 'curl -fsS --max-time 10 "http://localhost:40772/api/channels/GR/27/stream" -o /tmp/gr.ts; ls -l /tmp/gr.ts'
```

Expected: 数 MB 以上のファイルが得られる。

```bash
kubectl exec -n mahiron deploy/deployment -- bash -c 'curl -fsS --max-time 10 "http://localhost:40772/api/channels/EXT7/45168/stream" -o /tmp/ext7.ts; ls -l /tmp/ext7.ts'
```

Expected: 同上。0 バイトならリモート経路が機能していない。

- [ ] **Step 8: 利用側の疎通を確認する**

```bash
kubectl get pods -A | grep -E "konomitv|epgstation|telegraf|mirakurun-iptv-rewriter"
```

Expected: いずれも `Running` で、再起動回数が増えていない。

```bash
kubectl logs -n mirakurun-iptv-rewriter deploy/deployment --tail=50
```

```bash
kubectl logs -n konomitv deploy/deployment --tail=50 | grep -i "mirakurun\|error" | head -20
```

Expected: Mahiron への接続エラーが出ていないこと。

- [ ] **Step 9: 外形監視の復帰を確認する**

```bash
curl -fsS -o /dev/null -w '%{http_code}\n' https://mahiron.starry.blue/api/version
```

Expected: `200` (authentik の forward-auth を経由するため、リダイレクトになる場合は `-L` なしの挙動を確認する)

- [ ] **Step 10: 未定義チャンネルの 404 が発生していないか確認する**

設計文書で受容した回帰である。実際に踏んでいないことを見る。

アクセスログは構造化ログとして出るため、まず 1 行の形式を確認してから絞り込む。

```bash
kubectl logs -n mahiron deploy/deployment --tail=5 | grep -i "status\|method"
```

```bash
kubectl logs -n mahiron deploy/deployment --since=1h | grep -E "404" | grep -E "stream" | head -20
```

Expected: 出力なし。出る場合はどのチャンネルが要求されたかを確認し、必要なら `channels.yml` に追加する。

- [ ] **Step 11: コミット**

このタスクに新しいコミットはない。

---

### Task 6: 証跡を取得して PR に添付する

**Files:**
- Modify: PR 本文

**Interfaces:**
- Consumes: Task 5 の確認結果
- Produces: before / after を識別できる証跡

- [ ] **Step 1: before / after を並べた出力をまとめる**

Task 5 の Step 1 (before) と Step 5〜7 (after) の出力を対にして整理する。
最低限、次の 3 組を含める。

- `/api/version` の before / after (4 系 → 5 系)
- `/api/channels` と `/api/services` の件数の before / after
- ストリーム取得の結果 (ローカル GR とリモート EXT7)

- [ ] **Step 2: ダッシュボードのスクリーンショットを撮る**

5 系はダッシュボードを持つ。`playwright-cli` で `https://mahiron.starry.blue` を開いて撮る。

**スクリーンショットにリモート名や資格情報が写り込まないことを確認してから添付する。**
チャンネル一覧やチューナー一覧はリモート名を表示する可能性があるため、
状態表示 (Status) の画面に限定するか、写り込む場合は添付しない。

- [ ] **Step 3: PR に添付する**

`github-image-upload` スキル (`gh image upload`) を使う。

- [ ] **Step 4: コミット**

PR 本文の更新のみ。コミットは不要。

---

### Task 7: 切り戻し手順を確認する (実行はしない)

**Files:**
- なし

**Interfaces:**
- Consumes: Task 4 のコミット
- Produces: 切り戻しが成立することの確証

- [ ] **Step 1: 4 系のデータと設定が無傷であることを確認する**

```bash
ssh lily 'ls -la /mnt/local/mahiron/config /mnt/local/mahiron/data && md5sum /mnt/local/mahiron/config/tuners.yml'
```

Expected: Task 1 Step 5 で記録した md5 と一致する。
`services.json` / `programs.json` / `logo-data` が残っている。

- [ ] **Step 2: 切り戻し手順を PR 本文に記載する**

切り戻しは `k8s/apps/mahiron/lily/resources/deployment.yaml` の revert のみで完結する。
ホスト側の操作は不要である (`/mnt/local/mahiron5/` は残しておいてよい)。

```bash
git revert <Task 4 のコミット>
```

- [ ] **Step 3: コミット**

このタスクに新しいコミットはない。

---

## 未確定事項

- Task 2 Step 7 の期待値 (`routes` 29 件、`isDisabled: true` 7 件) は現行設定の分布から算出した見込みである。
  Task 2 Step 1 の出力と突き合わせて確定させる
- Task 5 Step 9 の外形監視は authentik の forward-auth を経由する。
  `ExternalMonitor` は `/api/version` を叩いており現行で 200 を返しているため、
  移行後も同じ経路で 200 になるはずだが、実際のレスポンスで確認する
