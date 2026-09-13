# ExternalMonitor の網羅と外形監視の 200 化

## 背景

稼働中の IngressRoute のホストは 27 件あるが、`ExternalMonitor` (`mackerel.starry.blue/v1alpha1`) は 14 件しか存在せず、13 ホストが外形監視の対象外になっている。

さらに、既存監視のうち 4 件 (`remote` / `influxdb` / `k8s` / `traefik`) は `expectedStatusCode: 302` を期待している。この 302 は authentik の forward-auth によるリダイレクトであり、Traefik と authentik が生きていることしか証明しない。バックエンドのアプリケーションが停止していても 302 は返るため、監視として機能していない。`traefik` のマニフェストには `# TODO: アプリケーションに到達できるようにし 200 を確認する` が残されている。

一方、forward-auth が有効なホストのうち一部は health パスで 200 を返す。これは authentik の Proxy Provider に設定された `skip_path_regex` (Unauthenticated Paths) によるものだが、この設定はコンソールでのみ管理されておりリポジトリには痕跡がない。監視が通っているのか、通っているとすればなぜなのかを、マニフェストを読んでも把握できない。

## 方針

認証の迂回は authentik のコンソール設定ではなく **IngressRoute の例外ルートとして表現する**。設定がアプリケーションのマニフェストに並び、レビューと差分追跡の対象になる。

その上で、全ての外形監視が 200 系のステータスコードを期待する状態にする。302 を期待する監視は残さない。

## 例外ルートの形

各アプリの `IngressRoute` に、`Path()` の完全一致ルートを追加する。`forward-auth-authentik` middleware は付けない。priority は 20 とする。

```yaml
- kind: Rule
  match: Host(`example.starry.blue`) && Path(`/healthz`)
  priority: 20
  services:
    - name: app
      port: http
```

priority 20 は、konomitv が `/sw.js` に対して既に使っている「アプリ固有の例外」の値である (こちらは認証の迂回ではなく 404 へのリダイレクト)。robots.txt の 100 は traefik namespace の別サービスへ流すためのもので意味が異なるため、この階層には置かない。catch-all の 10 と outpost の 15 のいずれよりも高いため、例外が優先される。

### 却下した代替案

- **`HostRegexp` で全ホスト共通の health ルートを 1 本作る**: `HostRegexp` ルートには `tls.options` が乗らず、そのパスだけ 421 を返す。過去に同じ構成で障害を起こしている。
- **各 namespace に軽量な health backend を置き、そこへ流す**: アプリケーション本体の生死を見ないため、監視の目的を満たさない。

## パスの選定基準

1. **公開しても情報が漏れないこと。** 例外ルートは認証なしでインターネットに露出する。アプリケーションの機能や状態を返すパスは選ばない。
2. **Cloudflare の既定キャッシュ対象拡張子を避けること。** 大半のホストが `cloudflare-proxied: true` であるため (`dns.starry.blue` のみ `false`)、`.js` や `.css` を監視するとオリジンが停止してもキャッシュから 200 が返り、障害を検知できない。

## Phase 1: 例外ルートの追加と監視の 200 化

対象は forward-auth 配下で 302 しか返らない 6 ホスト。

| ホスト | 追加する `Path()` | 転送先 | expectedStatusCode | 備考 |
| --- | --- | --- | --- | --- |
| `grafana-alloy.starry.blue` | `/-/ready` | `alloy:http-metrics` | 200 | 監視を新規作成 |
| `home.starry.blue` | `/manifest.json` | `home-assistant:http` | 200 | 監視を新規作成 |
| `1090.starry.blue` | `/version` | `ultrafeeder:http` | 200 | 監視を新規作成 |
| `remote.starry.blue` | `/api/languages` | `service:app` | 200 | 既存監視の URL を差し替え |
| `influxdb.starry.blue` | `/ping` | `influxdb:http` | 204 | 既存監視の URL を差し替え |
| `k8s.starry.blue` | `/healthz` | `kubernetes-dashboard-kong-proxy:kong-proxy-tls` | 200 | 既存監視の URL を差し替え |

選定の根拠:

- `1090` は tar1090 のバージョン文字列 1 行だけを返す `/version` を選ぶ。`/` はフロントエンドのシェルを公開してしまい、`/data/aircraft.json` や受信機の座標を含む `/data/receiver.json` は認証の内側に残す必要がある。`/data/status.json` と `/metrics` も 200 を返すが、受信状況が漏れるため採用しない。
- `influxdb` は本文で構成を返す `/health` ではなく、本文が空の `/ping` を選ぶ。204 を期待する。版数は `/ping` でも `X-Influxdb-Version` ヘッダーで返るため、そこは選定理由にならない。
- `home-assistant` は `/manifest.json` を選ぶ。`/auth/providers` は認証機構の構成を返すため採用しない。
- `k8s` の転送先は TLS を喋る kong-proxy であるため、例外ルートにも既存の catch-all と同じ `scheme: https` と `serversTransport: allow-insecure` を指定する。ポート名の指定だけでは疎通しない。

## Phase 2: Traefik

`traefik.starry.blue` に `Path(/ping)` のルートを追加し、`ping@internal` へ転送する。監視の URL を `/health` から `/ping` へ変更し、`expectedStatusCode` を 302 から 200 にして TODO コメントを削除する。

Traefik の Deployment には `--ping=true` が設定済みであることを確認済み。

`values.yaml` には「プラグインの取得に失敗すると全ルーターが読み込まれず 404 を返し続けるが、`/ping` は 200 のままなので probe では検知できない」というコメントがある。これは traefik entrypoint (内部ポート) 上の静的な ping ルートの話である。本設計では websecure entrypoint 上の**動的な** `IngressRoute` として ping を公開するため、ルーターテーブルが読み込まれなければこのルート自体が存在せず 404 になる。したがって、この盲点は生じず、むしろ既存の probe が検知できない障害を外形監視が検知できるようになる。

## Phase 3: 監視のみの追加

| ホスト | URL | expectedStatusCode | IngressRoute の変更 |
| --- | --- | --- | --- |
| `dns.starry.blue` | `/dns-query?dns=AAABAAABAAAAAAAAB2V4YW1wbGUDY29tAAABAAE` (`example.com` の A レコード照会) | 200 | 不要 (forward-auth 自体が無い) |
| `whoami.starry.blue` | `/` | 200 | 不要 (認証なし) |
| `code.starry.blue` | `/healthz` | 200 | `Path(/healthz)` の例外ルートを追加 |
| `cilium.starry.blue` | `/healthz` | 200 | `Path(/healthz)` の例外ルートを追加 |

`dns` は DoH のクエリを投げて 200 を確認する。パスの疎通ではなく名前解決そのものが成功することを検証できるため、このホストで最も意味のある監視になる。`Accept: application/dns-message` を付けなくても 200 が返ることを確認済みであり、`headers` の指定は不要である。`headers` を明示すると Mackerel が既定で挿入する `Cache-Control: no-cache` の管理をオペレータ側が引き取ることになるため、不要なら指定しない方がよい。

`code` と `cilium` は現在も 200 を返すが、それは authentik コンソール側の `skip_path_regex` に依存している。新規に作る監視が、リポジトリから見えない設定に依存する状態は避けたい。どちらも `/healthz` のみを開けていることを確認済みであり、IngressRoute の例外ルートと 1:1 で対応するため、監視の追加と同時に移行する。移行後は authentik 側の該当エントリが冗長になるため、「今後の課題」の棚卸し対象として記録する。

## 対象外

- **`router.starry.blue`**: LAN ルータ本体の Basic 認証により、クラスタ内から直接叩いても 401 を返す。200 を期待できない。
- **`epgstation-api.starry.blue` / `mahiron-api.starry.blue`**: API キーが必要で 401 を返す。`headers[].valueFrom.secretKeyRef` で資格情報を渡せば 200 監視が可能だが、今回のスコープからは外す。
- **`nebula.starry.blue` / `nebula-river.starry.blue` / `bit.starry.blue`**: 別リポジトリで管理されており、このリポジトリからは変更できない。

## 今後の課題 (本 spec の範囲外)

- **既存 6 ホストの移行**: `asf` / `epgstation` / `files` / `konomitv` / `mahiron` / `navidrome` は authentik 側の設定に依存して 200 を返している。うち 5 つは単一の health パスのみを開けており機械的に移行できる。**Navidrome だけは事情が異なり、単純な置き換えでは機能を壊す**ため、独立した設計を要する。
- **宙に浮いた Proxy Provider の棚卸し**: デプロイされていないアプリケーションの Proxy Provider が authentik にいくつか残っている。コンソール操作での整理が必要。
- **ultrafeeder の受信状況**: 調査中、`/metrics` が `readsb_aircraft_total 0` および `rssi_average -50.0` を返していた。一時的に機体が居ないだけの可能性もあるが、受信できていない可能性がある。

## 検証

ArgoCD の selfHeal により、マージ前に `kubectl apply` した変更は巻き戻される。したがって検証は次の 2 段階に分ける。

**マージ前** — 変更した全ての `IngressRoute` と `ExternalMonitor` に対し `kubectl apply --dry-run=server` を実行し、API サーバに受理されることを確認する。

**マージ後** — 各 URL を curl し、before (302) / after (200) を証跡として記録する。あわせて `kubectl get externalmonitor -o yaml` の `.status` を確認する。

既存 4 監視の URL と `expectedStatusCode` の変更が、Mackerel 側で**新規作成ではなく in-place な Update** として処理されることを確認する必要がある。監視が作り直されると monitor ID が変わり、コンソールで管理している通知グループとの紐付けが切れるためである。`ExternalMonitor` の `.status` には `monitorID` フィールドがあるため、変更の前後でこれを記録し、同一であることを示す。

`influxdb` に指定する `expectedStatusCode: 204` が Mackerel に受理されるかは `--dry-run=server` では判定できない。オペレータが Mackerel と同期して初めて確定するため、マージ後に当該監視の `.status` が `Ready` になることを個別に確認する。

## PR の分割

Phase 1 / Phase 2 / Phase 3 をそれぞれ 1 本の PR とし、Stacked PR として積む。レビュー単位が意味的に揃い、Phase 2 の Traefik 変更 (全ホストに影響しうる) を独立して切り戻せる。
