# ブラウザから Momiji のデスクトップを操作する

## 背景

Momiji (ワークステーション, 192.168.1.3) の画面を遠隔地から操作したい。
SSH と NAT 越えは既にあるが、GUI の操作手段がない。

Momiji は Plasma 6.7 の Wayland セッションで動いている。
Wayland では X11 前提の VNC サーバー (x11vnc, xrdp) が既存セッションを掴めないため、
コンポジタ側が提供するリモートデスクトップ機構を使う必要がある。
Plasma には KRdp があり、これは RDP サーバーとして既存セッションを配信する。

ただし RDP クライアントの導入をゲスト端末に要求したくない。
出先の端末に何も入れずブラウザだけで繋げることを要件とする。

## 方針

lily に Apache Guacamole を置き、HTML5 クライアントとして front に立てる。

```
ブラウザ (ゲスト端末)
  -> Cloudflare -> Traefik (lily)
  -> forward-auth-authentik
  -> guacamole (ns: guacamole)
       guacamole コンテナ  … Tomcat + HTML5 クライアント (8080)
       guacd コンテナ      … RDP プロトコル変換 (127.0.0.1:4822)
  -> 192.168.1.3:3389 (Momiji / KRdp)
```

authentik の RAC は同等の機能を内蔵するが Enterprise ライセンスを要する。
本クラスタの authentik は `licenseKey: dummy` であり、この選択肢は取れない。

## スコープ

- **対象**: `k8s/apps/guacamole/` の新設と ApplicationSet への登録
- **対象**: Momiji への `krdp` 導入とファイアウォールの調整
- **非対象**: Momiji 以外への接続先 (lily への SSH 等) の登録。まず RDP 1 経路で疎通と体感を確かめる
- **非対象**: bbc クラスタ。lily のみに載せる
- **非対象**: `remote.gateway.starry.blue`。Cloudflare を迂回する系統は用意せず、`remote.starry.blue` の 1 系統のみとする

## 分界点

| 層 | 対象 | 内容 |
| --- | --- | --- |
| リポジトリ | `k8s/apps/guacamole/` | マニフェスト一式 |
| リポジトリ | `k8s/system/argo-cd/resources/application/lily.yaml` | ApplicationSet への登録 1 件 |
| 1Password | 新規 item | `user-mapping.xml` の実体 |
| Momiji ホスト | `krdp` パッケージとファイアウォール | セッション配信の有効化 |

資格情報は 1Password 側に閉じる。
**RDP のパスワード、Guacamole のログインパスワードとそのハッシュは、
リポジトリ、PR、本ドキュメントのいずれにも記載しない。**

## 認証

Guacamole 自身の認証は `user-mapping.xml` によるファイルベースとし、PostgreSQL は立てない。

登録する接続は 1 つだけであり、利用者も 1 人である。
DB を立てると StatefulSet と PV と初期スキーマ投入が増えるが、得られるのは
Web UI からの接続編集だけで、この規模では釣り合わない。

実質的な認証は前段の `forward-auth-authentik` が担う。
Guacamole 自身のログイン画面はその後ろでもう一度出るが、
これは多層防御として残す。Service を直接叩かれた場合の最後の壁になる。

`guacamole-auth-header` による authentik との連携 (二重ログインの解消) は採用しない。
ヘッダ認証は前段を必ず通ることが前提であり、
クラスタ内から Service を直接叩かれると誰でも入れる状態になる。

### user-mapping.xml の受け渡し

このファイルには Guacamole のパスワードハッシュと Momiji の RDP パスワードの両方が入る。
公開リポジトリに置ける部分がないため、ファイルを丸ごと 1Password の 1 フィールドに持たせ、
`OnePasswordItem` から Secret を生成して `subPath` でマウントする。

ConfigMap にテンプレートを置き initContainer で環境変数を差し込む案は採らない。
ハッシュ側も秘密である以上 Git に残せるのは骨組みだけであり、可動部が増えるだけになる。

作成手順は次のとおり分担する。

1. テンプレートとハッシュ生成コマンドを用意する (実装側)
2. 値を埋めて 1Password の item を作成する (利用者)
3. item のパスを受け取り `secret.yaml` に書く (実装側)

## マニフェスト

| ファイル | 内容 |
| --- | --- |
| `resources/namespace.yaml` | ns `guacamole` |
| `resources/deployment.yaml` | guacamole + guacd の 2 コンテナ |
| `resources/service.yaml` | `app:8080` |
| `resources/ingress.yaml` | `remote.starry.blue` |
| `resources/dns.yaml` | DNSEndpoint と ExternalMonitor |
| `resources/secret.yaml` | OnePasswordItem |

### guacd の配置

guacd は同一 Pod の 2 つ目のコンテナとし、`GUACD_HOSTNAME=127.0.0.1` で参照する。
guacd を他から参照する必要はなく、Service を増やす理由がない。

### イメージ

- `guacamole/guacamole:1.6.0@sha256:f344085e618bb05e22b964b0208dbd06d3468275bac70206f93805245e067b40`
- `guacamole/guacd:1.6.0@sha256:8974eaa9ba32f713daf311e7cc8cd7e4cdfba1edea39eed75524e78ef4b08f4f`

### 起動時の挙動

Guacamole 1.6.0 の entrypoint について、次を実装前に確認済みである。

- 認証バックエンド必須のチェックはない。`GUACAMOLE_HOME` に `user-mapping.xml` を置くだけで起動する
- `GUACAMOLE_HOME` の既定値は `/etc/guacamole` である。entrypoint はこれをテンプレートとして扱い、
  中身を `/tmp` 配下に作った実 `GUACAMOLE_HOME` へリンクする
- Tomcat の `CATALINA_BASE` も `/tmp` 配下に `mktemp` で作られる
- webapp のコンテキストパスは `WEBAPP_CONTEXT` で決まる。既定は `guacamole` であり、
  `ROOT` を指定して `/` で配信する

したがって `readOnlyRootFilesystem: true` を維持したまま `/tmp` に emptyDir が要る。

### securityContext

実行ユーザーは各イメージの Dockerfile で固定されている。

| コンテナ | UID / GID |
| --- | --- |
| guacamole | 1001 / 1001 |
| guacd | 1000 / 1000 |

両コンテナとも `allowPrivilegeEscalation: false`、`capabilities.drop: [ALL]`、
`readOnlyRootFilesystem: true` とする。

### 監視

Guacamole に `/health` に相当する端点はない。
ExternalMonitor は `https://remote.starry.blue/` を 200 期待で見る。
これは forward-auth を通した他の app (navidrome 等) と同じ扱いである。

## Momiji ホスト側

### KRdp の bind 先

guacd は lily から接続するため、KRdp は LAN に bind する必要がある。
127.0.0.1 に閉じて SSH トンネルで使う構成とは両立しない。

代わりに Momiji 側のファイアウォールで 3389 の送信元を 192.168.1.2 (lily) のみに絞る。
lily は単一ノードであり、Cilium が Pod の egress をノード IP に masquerade する前提に立つ。
この前提は実装時に実測で確認する。

### 分担

- `krdp` の導入、リッスン状態の確認、ファイアウォールの調整は実装側で行う
- システム設定のリモートデスクトップでのユーザー名とパスワードの登録は利用者が行う

資格情報を実装側で入力も保持もしない。

## 接続パラメータ

初回は次を出発点とし、疎通後に絞る。

| パラメータ | 初期値 | 備考 |
| --- | --- | --- |
| `protocol` | `rdp` | |
| `hostname` | `192.168.1.3` | |
| `port` | `3389` | |
| `security` | `any` | KRdp との折衝結果を見て固定する |
| `ignore-cert` | `true` | KRdp の自己署名証明書のため |
| `resize-method` | `display-update` | 動的解像度 |

KRdp と Guacamole の組み合わせは未検証である。
security とキーボードレイアウトは初回接続の結果を見て調整する。

## 検証計画

### 1. マージ前

```bash
kubectl kustomize k8s/apps/guacamole
pnpm eslint
kube-linter lint --config .kube-linter.yaml k8s/apps/guacamole
```

### 2. Momiji 側

`krdp` 導入後、3389 が LAN 側で listen していることと、
lily の Pod から 3389 に到達できることを確認する。

### 3. マージ後

Argo CD の selfHeal により、マージ前に実クラスタへ当てた変更は巻き戻る。
実画面の確認はマージ後に行う。

`https://remote.starry.blue/` にブラウザでアクセスし、authentik の認証を通り、
Guacamole にログインして Momiji のデスクトップが表示され、
マウスとキーボードが効くところまでを確認する。

## 受容する制約

- Guacamole は RDP の H.264 (RemoteFX GFX) を使わず、独自プロトコルで画像を送る。
  動画再生やゲームの用途には向かない。管理作業とブラウジングを想定する
- KRdp はログイン済みセッションへの接続である。
  SDDM のログイン画面や、再起動後にセッションがない状態には接続できない
- ブラウザで Guacamole のログイン画面を 1 回余分に通る

## 今回見送る事項

- 接続先の追加 (lily への SSH 等)。必要になってから足す
- ヘッダ認証による二重ログインの解消。Service 直叩きへの耐性を落とすため採らない
- 再起動後も繋がるようにするための自動ログイン。運用して必要性が見えてから判断する
