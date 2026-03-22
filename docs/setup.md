# セットアップガイド

初回セットアップから初回デプロイまでの手順。

## 1. 必要なツールのインストール

```bash
brew install awscli opentofu jq python3
brew install --cask session-manager-plugin
pip install ansible
```

バージョン確認:

```bash
aws --version        # aws-cli/2.x.x
tofu --version       # OpenTofu v1.6.x
ansible --version    # ansible 2.15+
jq --version         # jq-1.x
python3 --version    # Python 3.11+
session-manager-plugin --version
```

## 2. AWS 設定

### IAM ユーザー作成

1. AWS コンソール → IAM → ユーザーを作成
2. ユーザー名: `minecraft-deployer`
3. 権限: `AdministratorAccess` を直接アタッチ
4. セキュリティ認証情報タブ → アクセスキーを作成 → CLI を選択
5. アクセスキーとシークレットキーをメモ（シークレットキーは一度のみ表示）

### AWS CLI プロファイル設定

```bash
aws configure --profile minecraft-prod
# AWS Access Key ID: <アクセスキー>
# AWS Secret Access Key: <シークレットキー>
# Default region name: ap-northeast-1
# Default output format: json
```

確認:

```bash
aws sts get-caller-identity --profile minecraft-prod
```

## 3. Discord Bot 設定

### アプリケーション作成

1. [Discord Developer Portal](https://discord.com/developers/applications) → New Application
2. 名前を入力（例: `Minecraft Server Bot`）→ Create
3. General Information ページで以下をメモ:
   - **APPLICATION ID**
   - **PUBLIC KEY**

### Bot トークン取得

1. 左メニュー → Bot → Reset Token
2. 表示されたトークンをメモ（一度のみ表示）

### Bot をサーバーに追加

1. 左メニュー → OAuth2 → URL Generator
2. SCOPES: `bot` + `applications.commands` にチェック
3. BOT PERMISSIONS: `Send Messages` + `Use Slash Commands` にチェック
4. 生成 URL をブラウザで開き、追加先サーバーを選択 → 認証

## 4. 初回デプロイ

### リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/minecraft-server-iac.git
cd minecraft-server-iac
```

### 初期設定（対話形式）

```bash
make init
```

以下を入力:
- Discord Application ID
- Discord Public Key
- Discord Bot Token
- RCON パスワード（空 Enter で自動生成）
- アラートメール（任意、空 Enter でスキップ）

生成ファイル: `.secrets/credentials.yml`, `.secrets/discord.env`, `tofu/environments/prod.tfvars`

### デプロイ（約 10〜15 分）

```bash
make deploy
```

実行内容: Lambda Layer ビルド → Tofu apply → Ansible setup → Ansible deploy

### Discord コマンド登録

```bash
source .secrets/discord.env
make discord-setup
```

出力された URL を Discord Developer Portal → General Information → INTERACTIONS ENDPOINT URL に設定 → Save Changes。

### 動作確認

Discord で `/server status` を実行。以下のような応答があれば成功:

```
📊 サーバーステータス
EC2 状態: 🟢 running
接続先: xx.xx.xx.xx:25565
```

## 5. ローカル開発環境（オプション）

AWS 料金をかけずに動作確認できる LocalStack 環境。

### 起動

```bash
# LocalStack（AWS モック）のみ
cd localstack
docker-compose up -d

# Minecraft サーバーも含める場合
docker-compose --profile minecraft up -d
```

### 確認

```bash
curl http://localhost:4566/_localstack/health
```

Minecraft クライアントから `localhost:25565` で接続可能。

### OpenTofu をローカルでテスト

```bash
cd tofu
tofu init
tofu plan -var-file=environments/local.tfvars
tofu apply -var-file=environments/local.tfvars
```

> LocalStack では EC2 の完全エミュレーションは不可。S3 / IAM / Lambda 等の一部サービスのみ対応。

### LocalStack 停止

```bash
cd localstack && docker-compose down
```
