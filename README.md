# Minecraft Server IaC

AWS 上に Minecraft サーバーを自動構築。Discord からサーバーの起動/停止ができます。

## 特徴

- **ワンコマンドデプロイ** - `make deploy` で本番環境が完成
- **Discord 操作** - `/server start` `/server stop` でサーバー管理
- **コスト最適化** - 使わない時は停止で月 $7 程度
- **自動バックアップ** - 毎日 S3 にワールドデータを保存
- **日本語対応** - ドキュメントは全て日本語

## クイックスタート

### 必要なもの

- AWS アカウント
- Discord アカウント（サーバー管理権限）
- Mac または Linux

### 手順

```bash
# 1. リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/minecraft-server-iac.git
cd minecraft-server-iac

# 2. 初期設定（対話形式で設定）
make init

# 3. デプロイ（10分程度）
make deploy

# 4. Discord コマンド登録
source .secrets/discord.env
make discord-setup
```

### 完了！

Discord で `/server status` を実行して動作確認！

## Discord コマンド

| コマンド | 説明 |
|----------|------|
| `/server start` | サーバーを起動（2-3分かかります） |
| `/server stop` | サーバーを停止 |
| `/server status` | 状態・接続先 IP を確認 |
| `/server backup` | 手動バックアップ |
| `/server logs` | サーバーログを表示 |

## コスト目安（東京リージョン）

| 状態 | 月額 |
|------|------|
| サーバー起動中 | 約 $30-40 |
| サーバー停止中 | 約 $7 |
| 完全削除 | $0 |

**使わない時は `/server stop` で停止しましょう！**

## ドキュメント

| ドキュメント | 内容 |
|--------------|------|
| [セットアップガイド](docs/setup-guide.md) | 詳細な手順説明 |
| [AWS 設定](docs/aws-setup.md) | AWS アカウント・IAM 設定 |
| [Discord 設定](docs/discord-setup.md) | Discord Bot の作成方法 |
| [運用ガイド](docs/operation-guide.md) | 日常の運用方法 |
| [トラブルシューティング](docs/troubleshooting.md) | よくある問題と解決方法 |
| [CI/CD 設定](docs/advanced/cicd-setup.md) | 自動デプロイ（上級者向け） |

## 🛠️ コマンド一覧

```bash
make help          # ヘルプを表示
make init          # 初期設定
make deploy        # デプロイ
make destroy       # 全削除（課金停止）
make status        # 状態確認
make ssh           # EC2 に接続
make logs          # Minecraft ログ表示
```

## ライセンス

MIT License

## Special Thanks

- [itzg/docker-minecraft-server](https://github.com/itzg/docker-minecraft-server)