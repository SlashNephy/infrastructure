# AGENTS.md

自宅 Kubernetes クラスタと Terraform で管理するインフラのマニフェスト置き場。

## このリポジトリは公開されている

**`SlashNephy/infrastructure` は PUBLIC リポジトリである。** ここに書いたものは誰でも読める。

対になる **`SlashNephy/private-infrastructure` は PRIVATE** である。公開したくないものはそちらに置く。

### 非公開リポジトリの詳細を持ち込まない

このリポジトリで扱うアプリケーションの多くは、**非公開リポジトリで開発されている**（`nebula` など）。それらの変更に追従して manifest を直すことは頻繁にあるが、次を PR タイトル・PR 説明・コミットメッセージ・コード内コメント・PR コメントに書いてはならない。

| 書いてはならないもの | 例 |
| --- | --- |
| 非公開リポジトリの Issue / PR 番号やリンク | `SlashNephy/nebula#1234`, `Close #1234` |
| 内部の識別子 | middleware 名、関数名、型名、パッケージ構成 |
| 内部の仕様・contract | エラーコードの意味、スコープ名、認可の判定ロジック |
| 開発中の設計や工程 | 「Phase 2 で実装する」「まだ骨組み」 |
| 非公開リポジトリ側の開発環境の構成 | ローカルのリバースプロキシ設定、テストの通し方 |

**書いてよいのは、このリポジトリの diff から誰でも読み取れる範囲までである。** ホスト名、Service 名、パス、middleware の有無などは manifest 自体に書かれているので問題ない。

変更理由を説明するときは、**インフラ側の観測可能な事実**に翻訳する。

> ❌ backend の `RequireXxxAccess` middleware が `Yyy` を検査し、不一致なら `401 zzz_error` を返す（内部の識別子・エラー semantics を晒している）
>
> ⭕ この経路はアプリケーション層で Bearer トークンによる認証を行うため、対話的なログインを前提とする forward-auth を通してはならない

### PR は AI レビューボットに読まれる

PR には CodeRabbit と Qodo が自動でレビューを投稿する。**PR 本文とコミットメッセージは第三者サービスに送られる**。後から編集しても、生成済みのコメントと本文の編集履歴は残る。書く前に確認する。

同じ理由で、force-push しても旧コミットは GitHub 上に dangling として残り、SHA を指定すれば取得できる。**コミットメッセージは push する前に見直す。**

## 構成

| ディレクトリ | 内容 |
| --- | --- |
| `k8s/apps/` | アプリケーション |
| `k8s/system/` | クラスタの土台（traefik, cert-manager, argo-cd, authentik など） |
| `k8s/cron/` | 定期実行ジョブ |
| `k8s/init/` | クラスタ構築時に一度だけ適用するもの |
| `k8s/common/` | 複数の app から参照する共通リソース |
| `terraform/` | Terraform Cloud で管理 |

クラスタは `lily` と `bbc` の 2 つ。どちらに載せるかは `k8s/system/argo-cd/resources/application-set-{lily,bbc}.yaml` の一覧で決まる。**新しい app を足したら、この ApplicationSet への登録も要る。**

## デプロイ

Argo CD が `master` を監視し、`automated` + `prune` + `selfHeal` で自動同期する。

- **master にマージすれば反映される。手動のデプロイ操作はない**
- `selfHeal: true` のため、`kubectl` で直接当てた変更はマニフェストの状態に巻き戻される
- 恒久的な変更は必ずマニフェストに書く

## 検証

```bash
kubectl kustomize --enable-helm k8s/apps/<name>    # レンダリング結果の確認
pnpm eslint                                        # YAML の lint
kube-linter lint --config .kube-linter.yaml <path> # マニフェストの静的検査
```

Helm chart を使う app は `charts/` に vendoring されている。`--enable-helm` を付けないとレンダリングできない。
