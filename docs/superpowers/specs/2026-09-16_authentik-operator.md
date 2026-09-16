# authentik-operator の導入

- ステータス: 承認済み
- 対象クラスタ: lily
- 作成日: 2026-09-16

## 目的

[authentik-operator](https://github.com/SlashNephy/authentik-operator) を lily に導入し、authentik の Application / Provider / アクセス権を CRD で宣言的に管理できる土台を作る。

本 PR のスコープは **operator 本体の導入のみ** とする。
`AuthentikApplication` CR による既存アプリケーションの移行は、operator が安定して稼働していることを確認したうえで別途行う。

## チャートの取得元

operator は kubebuilder 製で、チャートはリポジトリ内の `charts/chart` に置かれている。
ただし `main` の `Chart.yaml` の `version` は `0.1.0` のままで、リリース時に実際のバージョンへ書き換えられて gh-pages の Helm リポジトリに公開される。

したがって取得元は gh-pages の Helm リポジトリとする。

| 項目 | 値 |
| --- | --- |
| repo | `https://slashnephy.github.io/authentik-operator` |
| name | `authentik-operator` |
| version | `2026.8.0` |

これは同じく自作の mackerel-operator と同一の形であり、Renovate の kustomize manager がそのまま追従する。
`renovate.json5` の変更は要らない。

## 配置

`k8s/system/authentik-operator` に置く。
クラスタの土台を成すコンポーネントであり、authentik 本体と同じく `k8s/system` が妥当である。

Namespace は `authentik-operator` とする。
authentik 本体の Namespace には同居させない。operator は authentik の API クライアントに過ぎず、ライフサイクルが独立しているためである。

## 設定

### authentik への接続

`authentik.url` はクラスタ内部の Service を指す。

```
http://authentik-server.authentik.svc.cluster.local
```

Traefik の forwardAuth Middleware が既に使っている宛先と同じである。
公開 URL (`https://id.starry.blue`) は Cloudflare proxied を通るため、エッジの障害やレート制限の影響を受ける。
内部 Service であればそれらから独立し、`authentik.ca` の設定も要らない。

### 所有権マーカー

authentik には Kubernetes のラベルに相当するフィールドがないため、operator は authentik の RBAC Role を所有権マーカーとして使う。
`clusterName: lily` を渡すことで `authentik-operator-lily` という Role が起動時に自動生成される。
この Role には誰も所属しないため、アクセス制御には影響しない。

### トークン

authentik の API トークン (intent=api, expiring=false) を 1Password 経由で渡す。

- 1Password item: `authentik-operator` (Vault `4mogpcwrvtvsnpooum4vcevwkm`)
- フィールド名: `token`
- Kubernetes 側: `OnePasswordItem` が同名の Secret を生成し、チャートの `authentik.token.secretName` から参照する

operator は Role の作成と object permission の付与を行うため、トークンは superuser 相当の権限を持つ必要がある。

**トークンの発行と 1Password item への登録は手作業で、マージより先に済ませる。**
Secret 自体はこの変更に含まれる `OnePasswordItem` から生成されるため、初回同期で一時的に `CreateContainerConfigError` になるのは想定どおりで自然に解消する。
問題になるのは値のほうである。`AUTHENTIK_TOKEN` は `secretKeyRef` の env であり、コンテナ起動時にしか解決されない。
1Password Connect が Secret を更新しても、走っている Pod はダミー値を保持し続ける。
チャートの Deployment に Reloader のアノテーションはないため、ダミー値のままマージすると手動での再起動が要る可能性がある。

### 無効化する機能

| values | 値 | 理由 |
| --- | --- | --- |
| `metrics.enabled` | `false` | 現状このメトリックを収集するものがない。既定の `true` では未使用の Service と metrics 用 ClusterRole / ClusterRoleBinding が増える |
| `certManager.enabled` | `false` (既定) | webhook を持たず、metrics も無効のため証明書が要らない |
| `prometheus.enabled` | `false` (既定) | prometheus-operator を使っていない |
| `networkPolicy.enabled` | `false` (既定) | metrics 無効のため対象がない |
| `rbac.helpers.enabled` | `false` (既定) | admin/editor/viewer の補助 Role を配る相手がいない |

`rbac.namespaced` は既定の `false` のままとする。CR はアプリケーションごとの Namespace に置く想定であり、operator は全 Namespace を監視する必要がある。

## 変更するファイル

| ファイル | 内容 |
| --- | --- |
| `k8s/system/authentik-operator/kustomization.yaml` | 新規。helmCharts と valuesInline |
| `k8s/system/authentik-operator/resources/secret.yaml` | 新規。`OnePasswordItem` |
| `k8s/system/argo-cd/resources/application/lily.yaml` | system プロジェクトに 1 エントリ追加 |

## 検証

### マージ前

```bash
kubectl kustomize --enable-helm k8s/system/authentik-operator
kubectl kustomize --enable-helm k8s/system/authentik-operator | kubectl apply --dry-run=server -f -
pnpm eslint
kube-linter lint --config .kube-linter.yaml k8s/system/authentik-operator
```

server-side dry-run まで行う。CRD の新しいフィールドや alpha feature gate は client-side の検証をすり抜けて無言で破棄されることがあるためである。

### マージ後

Argo CD の selfHeal によりマージ前の手当ては巻き戻るため、実体の確認はマージ後に行う。

1. Pod が Ready であること
2. manager のログに `authentik-operator-lily` Role の作成が出ていること
3. authentik の Directory → Roles に `authentik-operator-lily` が存在すること (実画面)

ログを引用する際は、トークンを反映しうる行を含めない。
