# Mackerel ログ送信基盤の設計

## 背景と目的

Mackerel は 2026 年 7 月 16 日にログ機能をオープン β として公開した。
本設計は、lily クラスタのログを Mackerel に送る基盤を用意し、既存の Grafana Loki を将来的に縮小または廃止できるかを評価することを目的とする。

評価対象としたい点は次の二つである。

- **保管先としての代替可能性**：Loki が担っている保管と検索を Mackerel が肩代わりできるか
- **運用コスト**：正式リリース後の従量課金が、自宅クラスタの運用費として許容できる水準に収まるか

Mackerel のログ機能には、本設計の時点で次の制約がある。

- **保持期間**：30 日（Loki の現行設定と同じ）
- **料金**：β 期間中は無料、正式リリース後は 70 円/GB（税別）。課金対象は送信量のみで、保管とクエリは無料
- **ログ監視**：未実装。ログを起点にアラートを上げる機能はロードマップ段階にある
- **データ保持の保証**：β 期間中は保証されない

ログ監視が未実装であるため、本設計では Mackerel の既存の監視ルール（Terraform で管理している `mackerel_monitor_*`）との連携を扱わない。

## 現状

lily クラスタのログは Grafana Alloy が収集し、Loki に保管している。

```
Pod ログ ─┐
          ├─> Alloy ──(HTTP push)──> Loki ──(LogQL)──> Grafana
journald ─┘   DaemonSet              StatefulSet
              1 Pod                  3 Pod + 10Gi PV
```

`k8s/system/opentelemetry-collector`、`k8s/system/fluent-bit`、`k8s/system/openobserve-collector` の各ディレクトリは ArgoCD の ApplicationSet に登録されておらず、どのクラスタにもデプロイされていない。
このうち opentelemetry-collector の既存設定は `mode: deployment` でありながら `logsCollection` preset を有効にしている。
この preset は各ノードのログファイルを読む filelog receiver を追加するもので、DaemonSet を前提とする。
exporter が未設定のため実害は出ていないが、この設定をそのまま流用することはできない。

Mackerel 自体はメトリクス監視で既に運用している。
container-agent の sidecar 注入、mackerel-operator、Terraform による監視ルールの管理が稼働しており、API キーは 1Password Connect の `OnePasswordItem` で配布している。

## 実測

設計判断の根拠として、Loki の受信量を実測した。

### 全体の流量

`loki_distributor_bytes_received_total` を Loki の 22.18 日分の稼働から取得した。

| 項目 | 値 |
| --- | --- |
| 累計受信量 | 32.69 GB |
| 累計行数 | 6,113 万行 |
| 1 行あたり平均 | 535 bytes |
| 日次 | 1.474 GB/日 |
| 月次 | 44.8 GB/月 |
| 全量送信時の月額（70 円/GB） | 3,136 円 |

### namespace 別の内訳

直近 1 時間の LogQL クエリによる集計を示す（この時間帯は平均より流量が多く、日次換算で 2.969 GB/日に相当する）。

| namespace | GB/日 | 占有率 |
| --- | --- | --- |
| nebula | 1.842 | 62.1% |
| traefik | 0.945 | 31.8% |
| kube-system | 0.068 | 2.3% |
| その他 | 0.114 | 3.8% |

上位二つで全体の 93.9% を占める。

以降の表は別のタイミングで取得したため、合計値が本表と僅かに異なる。

### 発生源の内訳

nebula と traefik の中身をさらに分解した。

| 対象 | GB/日 | 備考 |
| --- | --- | --- |
| nebula の DBG | 1.724 | namespace 内の 94.6%。SQL クエリ全文を出力している |
| nebula の INF | 0.095 | |
| nebula の WRN と ERR | 0.003 | namespace 内の 0.16% |
| traefik の 2xx | 0.885 | namespace 内の 92.8% |
| traefik の 4xx | 0.054 | |
| traefik の 5xx | 0.000 | 計測期間中は発生なし |

クラスタ全体の約 88% が、デバッグログと正常時のアクセスログで占められている。

nebula backend の Deployment にはログレベルの設定が存在せず、アプリケーションの既定値である DEBUG のまま稼働している。

traefik のアクセスログは 1 レコードあたり平均 3,554 bytes に達する。
`--accesslog.fields.headers.defaultmode=keep` により、リクエスト、レスポンス、オリジン応答の三系統の HTTP ヘッダーがすべて記録されているためである。

| カテゴリ | bytes/rec | 占有率 |
| --- | --- | --- |
| `request_*`（リクエストヘッダー） | 1,094 | 31.2% |
| コアフィールド（ヘッダー以外） | 927 | 26.5% |
| `origin_*`（オリジン応答ヘッダー） | 685 | 19.6% |
| `downstream_*` のうち固定セキュリティヘッダー | 454 | 13.0% |
| `downstream_*` のその他 | 338 | 9.7% |

ヘッダーが全体の 73.5% を占める。
`origin_*` は `downstream_*` とほぼ同一の値を持つ重複であり、固定セキュリティヘッダー（`Strict-Transport-Security`、`Content-Security-Policy`、`X-Frame-Options` など）は毎リクエスト同じ値を返すため情報量がない。

## アーキテクチャ

OpenTelemetry Collector を新設し、Mackerel への送信を担わせる。
Alloy と Loki の既存経路は評価期間中そのまま並走させる。

```
┌─ lily クラスタ ────────────────────────────────────────────┐
│                                                            │
│  /var/log/pods ──> otel-agent (DaemonSet)                  │
│                     ├ filelog receiver                     │
│                     ├ k8sattributes                        │
│                     ├ transform (ANSI 除去, severity 付与) │
│                     ├ filter    (オプトアウト判定)         │
│                     ├ transform (サービス名, 優先度付与)   │
│                     ├ probabilistic_sampler                │──> Mackerel
│                     └ batch                                │
│                        ↑ OTLP :4317                        │
│  journald ──> Alloy ───┘                                   │
│                                                            │
│  k8s events ──> otel-cluster (Deployment ×1)               │──> Mackerel
│                                                            │
│  ※ Alloy → Loki の既存経路は変更せず並走                   │
└────────────────────────────────────────────────────────────┘
```

### Collector を二リリースに分ける理由

Helm chart の preset は、対応する動作モードが異なる。
`logsCollection` は DaemonSet を前提とし、`kubernetesEvents` は Deployment または StatefulSet を前提とする。
両方を使うには Helm リリースを二つ立てる必要があり、これは chart が想定した使い方である。

### イメージ

既存の設定と同じ `otel/opentelemetry-collector-k8s` を使う。
本設計が必要とするコンポーネントは、このディストリビューションにすべて含まれている。

- `filelogreceiver`、`k8seventsreceiver`、`k8sobjectsreceiver`、`otlpreceiver`
- `k8sattributesprocessor`、`transformprocessor`、`filterprocessor`、`probabilisticsamplerprocessor`、`batchprocessor`
- `otlphttpexporter`

より重量級の contrib イメージに切り替える必要はない。

### journald を Alloy 経由にする理由

OpenTelemetry の journald receiver は `journalctl` バイナリを実行する実装であり、ジャーナルを読むロジックを自前で持たない。
公式イメージ `otel/opentelemetry-collector-k8s` は distroless であり、`sh` すら含まない。
このイメージのままでは journald 収集は動作しない。

一方 Alloy の `loki.source.journal` は自前実装であり、`journalctl` に依存せず既に稼働している。
そこで journald の読み取りだけを Alloy に任せ、OTLP で Collector に渡す。

この構成において、Alloy は読み取り役に留まる。
Mackerel への送信、severity の付与、オプトアウト判定、サンプリングはすべて Collector 側で行い、Mackerel の API キーを持つのも Collector だけである。

Pod ログを Alloy 経由にしない理由は、Loki のラベル形式にある。
`loki.source.kubernetes` が付けるラベルは `namespace` や `pod_name` であり、Mackerel が前提とする OpenTelemetry のセマンティック規約（`k8s.namespace.name`、`k8s.pod.name`）と食い違う。
Pod ログは Collector が filelog receiver で直接読むことで、規約通りの属性が付く。
journald のラベルは `unit` 程度であり、そもそも Kubernetes の規約の対象外であるため、この問題は起きない。

Loki を廃止した後も Alloy は DaemonSet 1 Pod として残るが、役割は journald の読み取りだけに縮小する。
Loki の廃止によって回収できるのは 3 Pod と 10Gi のローカル PV であり、この縮小は Alloy を残しても得られる。

## リソース構成

```
k8s/system/opentelemetry-collector/
├── kustomization.yaml          # Helm リリース 2 つ（agent, cluster）
└── resources/
    ├── namespace.yaml
    └── secret.yaml             # OnePasswordItem で Mackerel API キーを配布
```

ApplicationSet への登録が必要である。
`k8s/system/argo-cd/resources/application-set-lily.yaml` に project `system` として追加しなければ、ディレクトリを作ってもデプロイされない。

## ログ属性の設計

Mackerel のログ検索は `service.namespace` と `service.name` の組で対象サービスを選ぶ流れになっている。
この二つの属性の設計が、そのまま画面での探しやすさを決める。

| 対象 | `service.namespace` | `service.name` |
| --- | --- | --- |
| Pod ログ | Kubernetes の namespace（`nebula`） | ワークロード名（`backend`） |
| journald | `lily` | `systemd` |
| Kubernetes Events | `lily` | `kubernetes-events` |

ワークロード名は `k8sattributes` processor が抽出する `k8s.deployment.name`、`k8s.daemonset.name`、`k8s.statefulset.name` のいずれかから決める。
いずれも取得できない場合は `k8s.pod.name` にフォールバックする。

## severity の判定

Pod の標準出力ログは、filelog receiver が読んだ時点では本文が文字列として Body に入るだけであり、`severity_number` は `UNSPECIFIED` のままである。
サンプリングを重要度で分けるには、送信前に severity を判定する工程が必要になる。

nebula のログは zerolog の ConsoleWriter 形式であり、レベル表記に ANSI カラーエスケープが混入している。

```
\x1b[2mAug  1 07:54:08.005\x1b[0m \x1b[92mINF\x1b[0m producer: Producer job counts
```

このため、ANSI エスケープの除去を先に行う。
順序を誤ると、後続の正規表現がレベル表記に一致しない。

```
1. ANSI エスケープの除去
   replace_pattern(body, "\x1b\[[0-9;]*m", "") where IsString(body)

2. JSON ログなら level フィールドから判定
   set(severity_number, SEVERITY_NUMBER_ERROR) where body["level"] == "error"

3. テキストログは本文から推定（zerolog の ERR / WRN 表記にも対応する）
   set(severity_number, SEVERITY_NUMBER_ERROR)
     where IsString(body) and IsMatch(body, "(?i)\b(err|error|fatal|panic)\b")
```

判定できなかったログは `UNSPECIFIED` のままとし、サンプリングの対象に含める。
判定漏れしたエラーが間引かれる可能性を負うが、多弁なアプリケーションのノイズを抑えることを優先する。

## オプトアウト

Pod のアノテーションで除外を指定する。
Deployment の `spec.template.metadata.annotations` に書けば Pod に伝播するため、ワークロード単位の指定として機能する。

```yaml
metadata:
  annotations:
    mackerel.io/logs: "false"
```

既存の設定で `kubernetesAttributes` preset の `extractAllPodAnnotations: true` が有効であるため、Pod のアノテーションは `k8s.pod.annotation.mackerel.io/logs` としてリソース属性に載る。
filter processor の OTTL 式からそのまま参照できる。

```yaml
filter/optout:
  logs:
    log_record:
      - 'resource.attributes["k8s.pod.annotation.mackerel.io/logs"] == "false"'
```

## サンプリング

`probabilistic_sampler` は既定で trace ID を参照する。
Kubernetes の標準出力ログに trace ID は存在せず、既定の `fail_closed: true` と組み合わさると全ログが破棄される。
`fail_closed: false` にすればサンプリングが一切効かなくなる。
どちらも意図と異なるため、`sampling_priority` によって明示的に制御する。

WARN 以上には優先度 100 を付与して無条件に通し、それ未満のみを確率的に間引く。

```yaml
transform/priority:
  log_statements:
    - set(attributes["sample_priority"], 100)
        where severity_number >= SEVERITY_NUMBER_WARN

probabilistic_sampler:
  sampling_percentage: 100    # 初期値。実測後に調整する
  sampling_priority: sample_priority
```

初期値を 100% とする理由は、後述の発生源の是正によって送信量が十分小さくなるためである。

ただし率を 100% 未満に下げる際は、`sampling_percentage` の変更だけでは足りない。
優先度を持たないログについて、ハッシュの種を明示する必要がある。

```yaml
probabilistic_sampler:
  mode: hash_seed
  sampling_percentage: 20
  attribute_source: record
  from_attribute: <種となる属性>
  sampling_priority: sample_priority
```

種の選び方によってサンプリングの意味が変わる。

- **`k8s.pod.uid`**：Pod 単位で採否が決まる。採用された Pod のログは全量残るため前後関係が保たれるが、まったく見えない Pod が生じる
- **transform で付与した UUID**：行単位で間引く。全 Pod から満遍なく残るが、スタックトレースが途中で欠ける

この選択は実際の流量を見てから判断する。

サンプリングはサーバの負荷を下げない。
パイプラインの終盤に位置するため、読み取り、パース、severity 付与という処理は全ログに対して既に走っている。
減るのは Mackerel への送信量、すなわち課金額だけである。

## 発生源の是正

送信量の設計としては、サンプリング率より発生源の見直しのほうが効果が大きい。

### nebula のログレベル

backend と worker の ConfigMap に `LOG_LEVEL=info` を追加する。
これにより DBG のログが止まり、1.724 GB/日が削減される。
Loki のディスク消費と Pod の CPU も同時に軽くなる。

### traefik のヘッダー

`defaultmode` を反転し、必要なヘッダーだけを明示的に残す。

```diff
- --accesslog.fields.headers.defaultmode=keep
- --accesslog.fields.headers.names.Authorization=redact
- --accesslog.fields.headers.names.Cookie=redact
- --accesslog.fields.headers.names.X-Authentik-Jwt=redact
+ --accesslog.fields.headers.defaultmode=drop
+ --accesslog.fields.headers.names.User-Agent=keep
+ --accesslog.fields.headers.names.Referer=keep
+ --accesslog.fields.headers.names.Origin=keep
+ --accesslog.fields.headers.names.X-Real-Ip=keep
+ --accesslog.fields.headers.names.Accept-Language=keep
+ --accesslog.fields.headers.names.Sec-Ch-Ua=keep
+ --accesslog.fields.headers.names.Sec-Ch-Ua-Mobile=keep
+ --accesslog.fields.headers.names.Sec-Ch-Ua-Platform=keep
+ --accesslog.fields.headers.names.Sec-Fetch-Site=keep
+ --accesslog.fields.headers.names.Sec-Fetch-Mode=keep
+ --accesslog.fields.headers.names.Sec-Fetch-Dest=keep
+ --accesslog.fields.headers.names.Cf-Connecting-Ip=keep
+ --accesslog.fields.headers.names.Cf-Ray=keep
+ --accesslog.fields.headers.names.Cf-Visitor=keep
+ --accesslog.fields.headers.names.Cf-Ipcountry=keep
+ --accesslog.fields.headers.names.Cf-Ipcity=keep
```

1 レコードは 3,554 bytes から約 1,422 bytes に減り、traefik の流量は 0.945 GB/日から約 0.38 GB/日になる。

Cloudflare が付与するヘッダーのうち、緯度経度（`Cf-Iplatitude`、`Cf-Iplongitude`）、郵便番号（`Cf-Postal-Code`）、タイムゾーン（`Cf-Timezone`）は keep しない。
アクセスの大半が自宅からである以上、これらを送ると生活圏の座標が SaaS 側に 30 日間保持される。
国と都市のレベル（`Cf-Ipcountry`、`Cf-Ipcity`）であれば分析用途を満たしつつ、粒度は穏当に収まる。

`defaultmode=drop` にすると `Authorization` と `Cookie` の `redact` 指定は不要になる。
今後クラスタに新しい機密ヘッダーが増えても、明示的に keep しない限りログに載らない。
redact の指定漏れという事故が構造的に起きなくなる。

### 是正の効果

| 段階 | クラスタ全体 | 月額（全量送信時） |
| --- | --- | --- |
| 現状 | 2.97 GB/日 | 3,136 円 |
| nebula 是正後 | 1.25 GB/日 | 1,320 円 |
| traefik 是正後 | 0.68 GB/日 | 約 720 円 |

サンプリングを 100% のままでも、正式リリース後の月額は約 720 円に収まる。

## 実施順序

1. 発生源の是正（nebula の `LOG_LEVEL`、traefik のヘッダー）
2. Collector の追加と ApplicationSet への登録
3. Alloy から journald を OTLP で橋渡し
4. Mackerel の画面で実データを確認し、サンプリング率を判断

手順 1 は Mackerel 導入と独立に効果があり、Loki のディスクと Pod の CPU を軽くする。
手順 2 の前に実施することで、Collector が扱う流量を最初から小さくできる。

## 検証

- Collector の Pod が起動し、`otelcol_exporter_sent_log_records_total` が増加すること
- Mackerel のログ画面で、`service.namespace` ごとにログが分類されて表示されること
- WARN 以上のログが Mackerel に届いていること
- `mackerel.io/logs: "false"` を付けたワークロードのログが Mackerel に届かないこと
- journald のログが Mackerel に届いていること
- 是正後の Loki 受信量が想定通り減っていること

## 未決事項とリスク

- **nebula アプリケーションが `LOG_LEVEL` 環境変数を参照するかは未確認である**。参照しない場合は、アプリケーション側の設定方法を調べ直す必要がある。
- **ANSI エスケープ除去の正規表現は実データでの動作確認が必要である**。OTTL の `replace_pattern` は RE2 を使うため、`\x1b` の記法が期待通り解釈されるかを実際のログで確かめる。
- **β 期間中はデータ保持が保証されない**。評価期間中に Loki を縮小しない理由がこれにあたる。
- **ログ監視が未実装であるため、Loki 廃止の判断は保留する**。Loki 側でログを起点にしたアラートを運用している場合、Mackerel だけでは代替できない。
