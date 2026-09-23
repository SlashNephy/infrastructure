# Bitnami チャートから公式イメージへの移行

- ステータス: 承認済み
- 対象クラスタ: lily
- 作成日: 2026-09-23
- 関連: #6027

## 目的

Bitnami のチャートと `docker.io/bitnamilegacy/*` イメージへの依存を、稼働中のアプリケーションから取り除く。

`bitnamilegacy` は更新停止済みのアーカイブであり、セキュリティ修正は提供されない。廃止予定日も公表されていない。
2026-08 に全てのイメージを `bitnamilegacy` へ固定したのは、pull 不能を避けるための暫定対応である。

## スコープ

lily で稼働しており、Bitnami に依存しているものを対象とする。

| app | コンポーネント | 現行チャート | 現行イメージ | データ量 |
| --- | --- | --- | --- | --- |
| `n8n` | PostgreSQL | `postgresql` 18.11.3 | `bitnamilegacy/postgresql:17.6.0` | 241M |
| `influxdb` | InfluxDB | `influxdb` 6.6.16 | `bitnamilegacy/influxdb:2.7.11` | 3.5G |
| `epgstation` | MariaDB | `mariadb` 27.3.0 | `bitnamilegacy/mariadb:12.0.2` | 480M |

次は対象外とする。

- `headlessx` / `immich` / `photoprism` / `stay-tuned` / `kubeclarity` / `librechat`: マニフェストは Bitnami を参照しているが、いずれの ApplicationSet にも登録されておらず稼働していない。今回は触らない
- 別リポジトリで管理しているアプリケーション: そちらで別途対応する

## 方式

### 公式イメージを自前のマニフェストで動かす

Bitnami のチャートを外し、公式イメージの StatefulSet（InfluxDB は既存に合わせて Deployment）、Service、必要なら ConfigMap を `resources/` に書く。

| 検討した方式 | 採否 | 理由 |
| --- | --- | --- |
| 公式イメージ + 自前マニフェスト | 採用 | いずれも単一インスタンスで、チャートの独自機能にほとんど依存していない。余計な抽象を挟まない |
| CloudPirates のチャート | 不採用 | 0.x 系で values の互換性が保証されない。InfluxDB が無い |
| CloudNativePG / mariadb-operator | 不採用 | 単一の小さな DB のためにオペレーターを 2 つ導入するのは過剰。データは dump / restore になる |

InfluxDB について、influxdata 公式チャートは appVersion が 2.7.4 で現行の 2.7.11 より古いため使わない。

イメージはリポジトリの慣習どおり、マニフェストに `public.ecr.aws/docker/library/*` を digest 付きで書き、Renovate で追従する。

### 既存 PVC をそのまま使う

データの dump / restore は行わない。公式イメージを `runAsUser: 1001` / `fsGroup: 1001` で動かし、データの場所を環境変数や起動引数で既存の Bitnami のレイアウトに向ける。

バージョンは現行と同一にする（`postgres:17.6` / `influxdb:2.7.11` / `mariadb:12.0.2`）。したがってオンディスクの形式は変わらず、切り戻しはマニフェストを戻すだけで済む。

公式イメージのエントリポイントが非既定の UID とパスで起動できない場合に限り、そのコンポーネントだけ dump / restore に切り替える。

## 共通の設計

- **Service 名を維持する。** `postgresql` / `influxdb` / `mariadb` の名前とポートを変えない。クライアント（n8n、Telegraf、Grafana、EPGStation）は変更しない
- **Secret を維持する。** 既存の Secret をそのまま使う。初期化済みの DB を使うので、DB 本体には初期化用の資格情報を渡さない。Secret を参照するのはクライアントとバックアップのジョブだけになる
- **既存の調整を移植する。** TZ、resources、probe の閾値、InfluxDB の NodePort（30086 / 30088）、MariaDB の起動フラグ一式
- **不要になった回避策を消す。**
  - PostgreSQL の preStop による fast shutdown: 公式イメージは `STOPSIGNAL SIGINT` を持つ
  - InfluxDB の `customStartupProbe`: チャートの誤ったコマンドを置き換えるためのものだった。自前の startupProbe（`/health`）として残す
- `updateStrategy` は既存どおり、host volume を使うものは `Recreate` 相当にする

## app ごとの差分

### n8n

- Bitnami チャートの backup CronJob（毎時 20 分に `pg_dumpall` を `n8n-postgresql-backup` へ書き出す）を、公式イメージで同等の CronJob に書き直す
- 既存の `cronjob-cleanup-backup` の対象パスと整合させる

### influxdb

- 管理トークンのファイルパスが変わるため、bucket 更新手順のコメントを直す
- boltdb と engine のパスを、既存 PVC 内の Bitnami のレイアウトに向ける

### epgstation

- `cronjob-db-maintenance` のクライアント用イメージを `mariadb:12.0.2` にする
- Bitnami チャートが生成していた `my.cnf` のうち、動作に必要なものを ConfigMap に移す
- Argo CD の自動同期が無効なため、マージ後に手動で同期する

## 検証

### 切り替え前

1. 本番の論理バックアップを、現行と同じ Bitnami イメージで作った手元のデータディレクトリに流し込む。それを公式イメージで、本番と同じ UID・パス・引数で `docker run` する（稼働中の PVC を直接コピーすると整合しないため）
2. 起動すること、既存データを読めること、クライアントから接続・クエリできることを確かめる
3. `kubectl kustomize --enable-helm` / `pnpm eslint` / `kube-linter` を通す

### 切り替え後

1. Pod のイメージ、再起動回数、ログを確認する
2. 実利用を確認する
   - n8n: ワークフローが実行され、backup CronJob が dump を書き出す
   - influxdb: Telegraf の書き込みが継続し、Grafana のクエリが返る
   - epgstation: 予約一覧の API が返り、`db-maintenance` が成功する

## 進め方

app ごとに PR を分ける。互いに依存しないため Stacked PR にはしない。

1. `n8n`: 最も小さく、バックアップの仕組みもある
2. `influxdb`
3. `epgstation`: 録画に直結し、同期も手動のため最後にする

問題があれば PR を revert する。ただし、移行後の公式イメージは Renovate が更新を自動マージする (2026-09-23 にユーザー判断で現状維持)。マイナー以上の更新が入った後は、revert による Bitnami への切り戻しは成り立たない前提で扱う。

マージ直前の論理バックアップは n8n では既存の毎時バックアップで代えた。influxdb はバージョンを変えずにデータをそのまま使うので取らない (ユーザー判断)。
