# lily の Mahiron を 5 系に移行する

## 背景

lily の `mahiron` namespace は Mahiron 4 系のイメージで動いている。
これを Mahiron 5 系のイメージ (`ghcr.io/starrybluesky/mahiron5-custom`) に移行する。

Mahiron 5 は 4 系の後継バージョンではなく、別リポジトリの別実装である。
4 系が Mirakurun フォークの Node.js 実装であるのに対し、5 系は Go で書き直されており、
永続化層も JSON ファイルから SQLite に変わっている。
Mirakurun 互換 API は維持されているため、`/api` を叩く側 (KonomiTV, EPGStation, telegraf,
mirakurun-iptv-rewriter, 相互共有先) から見た互換性は保たれる。
一方で設定ファイルとデータは互換性がなく、移行作業の実体はその書き換えである。

## スコープ

対象は lily のみとする。

- **対象**: `k8s/apps/mahiron/lily`、および lily ホスト上の設定
- **非対象**: `k8s/apps/mahiron/bbc` (現在稼働していないため、今回は 4 系のまま据え置く)
- **非対象**: Mahiron 5 が備える OpenTelemetry 連携 (別 PR とする。理由は「今回見送る事項」を参照)

## 分界点

変更は 2 層に分かれる。

| 層 | 対象 | 内容 |
| --- | --- | --- |
| リポジトリ | `k8s/apps/mahiron/lily/resources/deployment.yaml` | image / args / mount パス / env |
| lily ホスト | `/mnt/local/mahiron5/config/` | 設定 4 ファイルを新規作成 |

リポジトリに入る差分は Deployment 1 ファイルに閉じ、作業量とリスクの大半はホスト側の設定書き換えに集中する。
ホスト側の設定には相互共有先の資格情報が含まれるため、この分離は
公開リポジトリに認証情報を持ち込まないための境界も兼ねる。
**設定の実値 (ホスト名、資格情報) はリポジトリ、PR、本ドキュメントのいずれにも記載しない。**

## データ領域

`/mnt/local/mahiron5/{config,data}` を新設し、4 系の `/mnt/local/mahiron/` には一切触れない。

Mahiron 5 の永続化層は SQLite (`mahiron.db` と `data-broadcast-cache.db`) であり、
4 系の `services.json` / `programs.json` / `logo-data` からの移行パスは存在しない。
初回起動でサービススキャン、EPG 取得、ロゴ取得をやり直すことになる。これは受容する。

ディレクトリを分離することで、切り戻しは Deployment の revert のみで完結する。

## ホスト側の設定

### `server.yml`

4 系とは非互換であり、全面的に書き換える。要点は次の 3 つ。

- `addresses` の既定値は `localhost:40772` である。明示的に全インターフェースを指定しないと
  Pod の外からは到達できなくなる
- `databasePath` と `dataBroadcastCachePath` の既定値は作業ディレクトリ配下の相対パスであり、
  明示しないとコンテナの揮発領域に書かれる。とくに後者は既定で 1 GiB を上限とするキャッシュである
- `logLevel` は整数から文字列 (`debug` / `info` / `warn` / `error`) に変わった

```yaml
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
```

4 系で使っていた `programGCInterval` / `epgGatheringInterval` / `randomizeTuners` /
`maxPendingPromises` に対応する設定は存在しない。
EPG 収集は固定間隔での実行から cron 式のジョブに変わったため、`jobs` で明示する。

### `tuners.yml`

ローカルのチューナー定義 16 本はそのまま残す。
コマンドテンプレートのプレースホルダは 4 系と同じ `<channel>` 形式が有効である。

リモート取り込み用に定義していた 8 本は削除する。
これらは後述の `remotes.yml` と `routes` に置き換わる。

### `remotes.yml`

新規作成する。Mirakurun 互換サーバーへの接続情報 (名前、URL、Basic 認証) を定義する。

リモート名は現行の外部サーバー定義のキーをそのまま流用し、実値はホスト側にのみ置く。

### `channels.yml`

GR / BS / CS の 47 件は変更しない。
リモート取り込みの 31 件は、4 系で使っていたチャンネル単位のコマンド指定を削除し、
`routes` に置き換える。

`routes` は 1 つの論理チャンネルに複数の取得経路をぶら下げ、`priority` で優先順位を付ける仕組みである。
`remote` を指定した経路はリモートから HTTP でストリームを引くため、ローカルチューナーを消費しない。
また経路ごとにリモート側のチャンネル種別を指定できるため、
lily 側の種別とリモート側の種別が異なる場合もそのまま表現できる。

チャンネル種別 `EXT1` 〜 `EXT7` は現行のまま維持する。
Mahiron 5 のチャンネル種別は自由文字列であり、そのまま受理される。
種別を変えると KonomiTV や相互共有先から見えるチャンネルの見え方が変わるため、変更しない。

| 種別 | 件数 | 経路 | 備考 |
| --- | --- | --- | --- |
| EXT1 | 7 | 単一 | リモート側種別は `EXT1` |
| EXT2 | 5 | 3 段フォールバック | リモート側種別は `GR`。bbc を指す経路は無効化 |
| EXT3 | 1 | 2 段フォールバック | リモート側種別は `GR` |
| EXT4 | 3 | 単一 | リモート側種別は `GR` |
| EXT5 | 3 | 単一 | リモート側種別は `GR` |
| EXT6 | 2 | なし | チャンネルごと `isDisabled: true` |
| EXT7 | 10 | 単一 | リモート側種別は `BS4K` |

4 系ではフォールバック先を 1 つのコマンド引数にカンマ区切りで並べていた。
これは `routes` と `priority` が表現するために用意された構造そのものであり、
移行は機能の代替ではなく本来の記法への移動になる。

#### EXT6 の扱い

EXT6 の 2 チャンネルは bbc が唯一の供給元であり、bbc は稼働していない。
チャンネル定義は残したうえで `isDisabled: true` を付け、無効であることを設定に明示する。
EXT2 のフォールバック経路のうち bbc を指すものも同様に無効化する。

#### EXT4 の修正

EXT4 の 3 チャンネルは、4 系ではサービス情報と EPG は取得できるがストリームを取得する経路がない。
リモート取り込み用チューナーが定義されていないためである。
`routes` 化に伴い、他の種別と同じ形でストリーム経路を定義する。
移行によりストリームが取得できるようになるため、これは挙動の変化を伴う改善である。

## Deployment の差分

| 項目 | 変更内容 |
| --- | --- |
| `image` | `ghcr.io/starrybluesky/mahiron5-custom:master@sha256:...` に変更 (digest は実装時に解決) |
| `args` | `["-config-dir", "/etc/mahiron"]` を追加 |
| `env` | 4 系のリモート取り込みに使っていた環境変数を削除 |
| `volumes` | `config` / `data` の hostPath を `/mnt/local/mahiron5/{config,data}` に変更 |
| `volumes` | 空のまま使われていない `check-services` のマウントを削除 |

`/dev/px4video*` および `/dev/pxmlt8video*` のデバイスマウント、`privileged`、
`hostNetwork`、`securityContext`、Service、IngressRoute、DNSEndpoint は変更しない。

`args` の追加は、イメージが既定で参照する設定ディレクトリが `/etc/mahiron` ではないためである。

## 検証計画

### 1. 設定パース検証

本番切替の前に、新しい設定が読めることを確認する。

ローカルチャンネルをすべて `isDisabled: true` にした検証用の設定を用意し、
`hostNetwork` なし・別ポートの使い捨て Pod で起動する。
本番のチューナーを奪わずに、設定ファイルのパースとリモート同期の成立を確認する。

Mahiron 5 の設定読み込みは未知のキーをエラーとして扱うため、
書き換え漏れは起動時に失敗として現れる。

### 2. 本番切替後の確認

| 確認対象 | 方法 |
| --- | --- |
| バージョン | `/api/version` が 5 系を返すこと |
| 稼働状態 | `/api/status` |
| チャンネル・サービス | `/api/channels` と `/api/services` の件数が移行前と一致すること |
| リモート取り込み | EXT の各系統でサービスと EPG が揃うこと |
| ストリーム | ローカル GR 1 本とリモート EXT7 1 本の疎通 |
| 利用側 | KonomiTV / EPGStation / telegraf / mirakurun-iptv-rewriter の疎通 |
| 外形監視 | `mahiron.starry.blue` の ExternalMonitor が復帰すること |

### 3. 切り戻し

Deployment を revert するだけで 4 系に戻る。
`/mnt/local/mahiron/` は移行作業中も一切変更しないため、データは無傷である。

## 受容した挙動の変化

- **未定義チャンネルへのストリーム要求が 404 になる**。
  4 系では `channels.yml` に定義のないチャンネルへの要求も受け付けていた。
  lily の `channels.yml` は 78 チャンネルを網羅しており実害はないと判断する。
  切替後にアクセスログで 404 が出ていないことを確認する
- **EPG とロゴを再取得する**。初回起動でスキャンからやり直す
- **リモート経路の同時視聴本数の上限が外れる**。
  4 系ではリモート取り込み用チューナーの本数 (各 2 本) が同時接続数の上限として働いていた。
  `routes` の経路はチューナーを消費しないため、この制限はなくなる
- **EPG 収集が固定間隔から cron ジョブに変わる**。収集タイミングが変わる

## 今回見送る事項

- **OpenTelemetry 連携**。
  Mahiron 5 は OTLP を組み込みで持つが、このクラスタの Collector は OTLP gRPC のみを受信し、
  metrics と traces のパイプラインは破棄する構成になっている。
  一方 Mahiron 5 は OTLP HTTP で送信する。
  有効化するには Collector 側に受信口とパイプラインを追加する必要があり、移行とは別の変更になる
- **bbc の移行**。稼働していないため対象外とする。
  結果としてイメージが 2 系統残り、Renovate の追跡対象も二重になる
