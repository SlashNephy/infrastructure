# authentik Application の CR 移行 (第 1 弾: whoami / file-browser)

- ステータス: 承認済み
- 対象クラスタ: lily
- 作成日: 2026-09-16
- 前提: [authentik-operator の導入](2026-09-16_authentik-operator.md)

## 目的

authentik の Application を `AuthentikApplication` CR で宣言的に管理する。
lily の authentik には 23 個の Application があるが、一度に移すのは危険なので、影響の小さい 2 つから始めて operator の 2 つの経路を実地で検証する。

| アプリ | 検証する経路 | 選んだ理由 |
| --- | --- | --- |
| whoami | create | Provider を持たず、認証もかかっていない。壊れても影響がない |
| file-browser | adopt | Proxy Provider と PolicyBinding を持つ典型的な構成。かつ利用者が限られる |

whoami は本設計のために authentik のコンソールから一度削除した。
CR が作り直すことで create 経路を検証する。

## 調査時の落とし穴

`GET /api/v3/core/applications/` は既定で全件を返さない。
23 件のうち 21 件しか出ず、whoami と nebula-frontend が欠けていた。
`search=whoami` も空を返す。

全件を得るには `superuser_full_list=true` が要る。
個別の `GET /api/v3/core/applications/whoami/` は既定でも 200 を返すので、**一覧に出ないことを存在しない根拠にしてはならない。**

## 配置

CR はアプリ自身の manifest と同居させる。
`ExternalMonitor` を各アプリの `dns.yaml` に置いている既存の慣習と同じ考え方で、認証の設定を参照元の IngressRoute の隣に置く。

| アプリ | ファイル | Namespace |
| --- | --- | --- |
| whoami | `k8s/system/traefik/lily/resources/whoami/resources/authentik.yaml` | `traefik` |
| file-browser | `k8s/apps/file-browser/resources/authentik.yaml` | `file-browser` |

CRD は Namespaced だが、operator はテナント分離を行わず、どの Namespace の CR からでも authentik の任意の Group や Policy を参照できる。
Namespace はあくまで manifest の置き場所の都合で決めてよい。

## whoami

```yaml
apiVersion: authentik.starry.blue/v1alpha1
kind: AuthentikApplication
metadata:
  name: whoami
spec:
  slug: whoami
  name: whoami
  launchURL: https://whoami.starry.blue
  access:
    public: true
```

- `adopt` は書かない。既定の `Never` のままとする。
  slug で見つからなければ create 経路に入るので adopt は関与しない。
  既定のままにしておけば、将来誰かが手で whoami を作り直したときに黙って取り込むこともない。
- `group` / `icon` / `description` / `publisher` は削除前の状態がすべて空だったので書かない。
- `access.public: true` は「全ユーザーがアクセス可能」を明示する。PolicyBinding は作られない。
- Provider は持たせない。whoami は Traefik の経路そのものが生きていることを確認する合成監視の対象であり、認証をかけると目的と衝突し、200 を期待する `ExternalMonitor` も壊れる。

### 削除前の状態 (create 後の比較基準)

```json
{
  "slug": "whoami",
  "name": "whoami",
  "group": "",
  "meta_launch_url": "https://whoami.starry.blue",
  "meta_icon": "",
  "meta_description": "",
  "meta_publisher": "",
  "open_in_new_tab": false,
  "policy_engine_mode": "any",
  "provider": null
}
```

PolicyBinding は 0 件だった。

## file-browser

```yaml
apiVersion: authentik.starry.blue/v1alpha1
kind: AuthentikApplication
metadata:
  name: file-browser
spec:
  slug: file-browser
  name: FileBrowser
  group: Multimedia
  icon: https://raw.githubusercontent.com/gtsteffaniak/filebrowser/main/frontend/public/img/icons/favicon.svg
  adopt: IfMatch
  provider:
    name: file-browser
    flows:
      authentication:
        slug: sign-in
      authorization:
        slug: authorize
      invalidation:
        slug: default-provider-invalidation-flow
    proxy:
      forwardAuthSingle:
        externalHost: https://files.starry.blue
      interceptHeaderAuth: true
      accessTokenValidity: days=1
      refreshTokenValidity: days=30
      outpost:
        name: authentik Embedded Outpost
  access:
    rules:
      - group:
          name: Nerd
```

参照フィールドはすべてオブジェクト形式である。
`group: Nerd` のような文字列は CRD の検証で弾かれる (`must be of type object`)。
将来 Group が CRD 化されたときに `groupRef` などを足せるようにするための形である。

`adopt: IfMatch` とする。
CR に書いたフィールドが authentik の現状と一致したときだけマーカーを付ける。
転記ミスがあれば `Ready=False` / `AdoptionDiff` で止まり、status に差分が出るだけで書き込みは一切起きない。

### 意図的に書かないもの

| フィールド | 理由 |
| --- | --- |
| `description` | 現在の値に Discord のハンドルが入っている。このリポジトリは公開されているため CR に書けない。spec から省けば operator は触らず、authentik 側の値がそのまま残る |
| `unauthenticatedPaths` | 現在 `skip_path_regex` は空。`/health` の認証迂回は IngressRoute 側で表現する方針が既にコメントで明示されており、それを維持する |
| `access.prune` | 既定の `false`。operator の管理外の Binding を消さない |

`deletionPolicy` は両方とも既定の `Retain` とする。
CR を消しても authentik 側のオブジェクトは残るので、切り戻しが効く。

## 検証

### マージ前

```bash
kubectl kustomize --enable-helm k8s/system/traefik/lily
kubectl kustomize --enable-helm k8s/apps/file-browser
go run ./cmd/build-manifests
pnpm eslint
```

レンダリング結果を `kubectl apply --dry-run=server` に通し、CRD のスキーマに適合することを確認する。

### マージ後

Argo CD は selfHeal で自動同期するため、実体の確認はマージ後になる。

**whoami (create)**

1. 上記「削除前の状態」と作成後の API レスポンスの diff が空であること
2. PolicyBinding が 0 件であること (`access.public: true` が余計な Binding を作らないこと)
3. `https://whoami.starry.blue/` が 200 のままであること
4. library ダッシュボードに whoami が出ること

**file-browser (adopt)**

1. Application / Provider / PolicyBinding がマージ前と一字一句変わっていないこと。
   adopt はマーカーを付けるだけなので、diff が空であることが正しい証跡である
2. `https://files.starry.blue` に実際にブラウザでアクセスし、認証が今まで通り動くこと

**共通**

1. 両 CR が `Ready=True` であること
2. `GET /rbac/permissions/roles/?uuid=<authentik-operator-lily の uuid>` にマーカーが並ぶこと

## 今回のスコープ外

- 残り 21 個の Application の移行
- OAuth2 Provider を持つ Application (argo-cd, grafana, nebula) の移行。
  Proxy とは spec の形が異なるので、別途 1 つで試してから広げる
- `nebula-frontend` の扱い。一覧に出てこない理由を調べていない
