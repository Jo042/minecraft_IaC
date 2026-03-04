# セットアップガイド

このガイドでは、Minecraft Server IaC のセットアップ手順を詳しく説明します。

## 目次

1. [前提条件](#前提条件)
2. [AWS 設定](#aws-設定)
3. [Discord 設定](#discord-設定)
4. [デプロイ](#デプロイ)
5. [動作確認](#動作確認)

## 前提条件

### 必要なツール

以下のツールをインストールしてください。

| ツール | インストール方法（Mac） |
|--------|------------------------|
| AWS CLI | `brew install awscli` |
| OpenTofu | `brew install opentofu` |
| Ansible | `pip install ansible` |
| jq | `brew install jq` |
| Python 3 | `brew install python3` |

### 確認方法

```bash
aws --version      # aws-cli/2.x.x
tofu --version     # OpenTofu v1.6.x
ansible --version  # ansible 2.15+
jq --version       # jq-1.x
python3 --version  # Python 3.11+


## AWS 設定

詳細は [AWS 設定ガイド](aws-setup.md) を参照してください。

### 簡易手順

1. AWS アカウントを作成（持っていない場合）
2. IAM ユーザーを作成
3. AWS CLI にプロファイルを設定

```bash
aws configure --profile minecraft-prod
# AWS Access Key ID: あなたのアクセスキー
# AWS Secret Access Key: あなたのシークレットキー
# Default region name: ap-northeast-1
# Default output format: json
```

## Discord 設定

詳細は [Discord 設定ガイド](discord-setup.md) を参照してください。

### 簡易手順

1. [Discord Developer Portal](https://discord.com/developers/applications) にアクセス
2. 「New Application」でアプリを作成
3. 以下をメモ:
   - Application ID
   - Public Key
   - Bot Token

## デプロイ

### 1. リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/minecraft-server-iac.git
cd minecraft-server-iac
```

### 2. 初期設定

```bash
make init
```

対話形式で以下を入力します:
- Discord Application ID
- Discord Public Key
- Discord Bot Token
- RCON パスワード（自動生成可）
- アラートメール（任意）

### 3. デプロイ

```bash
make deploy
```

これにより以下が自動で実行されます:
1. Lambda Layer のビルド
2. AWS インフラの構築（VPC, EC2, Lambda 等）
3. EC2 の初期設定（Docker インストール）
4. Minecraft サーバーのデプロイ

**所要時間: 約10-15分**

### 4. Discord コマンド登録

```bash
source .secrets/discord.env
make discord-setup
```

表示される URL を Discord Developer Portal の「Interactions Endpoint URL」に設定します。

## 動作確認

### Discord でコマンド実行

```
/server status
```

以下のような応答があれば成功です:

```
📊 サーバーステータス
EC2 状態: 🟢 running
接続先: 54.x.x.x:25565
Minecraft: 🟢 オンライン
プレイヤー: 0/20 人
```

### Minecraft から接続

1. Minecraft を起動
2. マルチプレイ → サーバーを追加
3. サーバーアドレスに表示された IP を入力
4. 接続！

## 次のステップ

- [運用ガイド](operation-guide.md) - 日常の運用方法
- [トラブルシューティング](troubleshooting.md) - 問題が発生した場合