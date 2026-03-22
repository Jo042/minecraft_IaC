# Minecraft Server IaC

AWS 上に Minecraft サーバーを自動構築し、Discord から起動・停止・バックアップを操作できる IaC プロジェクト。

OpenTofu でインフラを定義し、Ansible でサーバーを構成。Discord Bot は Lambda（Handler + Worker の二段構成）で実装。EC2 へのアクセスは SSH キー不要の SSM Session Manager を使用。

## Prerequisites

| ツール | インストール（Mac） |
|--------|---------------------|
| AWS CLI | `brew install awscli` |
| OpenTofu | `brew install opentofu` |
| Ansible | `pip install ansible` |
| jq | `brew install jq` |
| Python 3.11+ | `brew install python3` |
| Session Manager Plugin | `brew install --cask session-manager-plugin` |

## クイックスタート

```bash
git clone https://github.com/YOUR_USERNAME/minecraft-server-iac.git
cd minecraft-server-iac

make init     # AWS・Discord 情報を対話形式で設定
make deploy   # インフラ構築 + サーバーデプロイ（約 10〜15 分）

source .secrets/discord.env
make discord-setup  # Discord コマンド登録
```

詳細は [セットアップガイド](docs/setup.md) を参照。

## コマンド一覧

| コマンド | 内容 |
|----------|------|
| `make deploy` | フルデプロイ（インフラ + Ansible） |
| `make server-start` | Minecraft コンテナ起動 |
| `make server-stop` | Minecraft コンテナ停止 |
| `make backup` | S3 に手動バックアップ |
| `make restore` | S3 から復元（対話形式） |
| `make upgrade` | バージョンアップ（対話形式） |
| `make status` | インフラ状態を表示 |
| `make ssh` | EC2 に SSM で接続 |
| `make logs` | サーバーログをリアルタイム表示 |
| `make plan` | インフラ変更の dry-run |
| `make apply` | インフラのみ適用（Ansible なし） |
| `make destroy` | 全リソース削除 |
| `make test` | Python テスト実行 |

## コスト目安（東京リージョン）

| 状態 | 月額 |
|------|------|
| 起動中 | 約 $30〜40 |
| 停止中 | 約 $7 |
| 完全削除 | $0 |

## ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [セットアップ](docs/setup.md) | 初回セットアップ・初回デプロイ |
| [運用ガイド](docs/operations.md) | 日常操作・バックアップ・トラブルシューティング |
| [技術リファレンス](docs/technical.md) | アーキテクチャ詳細・CI/CD・設計判断 |

## License

MIT — [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)
