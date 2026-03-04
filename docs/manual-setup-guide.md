# 手動セットアップ & 運用ガイド

Makefile や init-setup.sh を使わず、手動でセットアップ・運用する手順です。

## 前提条件

以下がインストール済みであること：
- AWS CLI
- OpenTofu
- Ansible
- Python 3.11+
- jq

## 1. 初期セットアップ

### 1.1 リポジトリをクローン

```bash
git clone https://github.com/YOUR_USERNAME/minecraft-server-iac.git
cd minecraft-server-iac
```

### 1.2 Python 環境をセットアップ

```bash
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Ansible コレクション
cd ansible
ansible-galaxy collection install -r requirements.yml
cd ..
```

### 1.3 AWS プロファイルを設定

```bash
aws configure --profile minecraft-prod
# Access Key, Secret Key, Region (ap-northeast-1) を入力
```

### 1.4 設定ファイルを作成

**tofu/environments/prod.tfvars:**

```bash
cp tofu/environments/prod.tfvars.example tofu/environments/prod.tfvars
vim tofu/environments/prod.tfvars
```

以下を編集：
```hcl
discord_public_key     = "あなたのPublic Key"
discord_application_id = "あなたのApplication ID"
rcon_password          = "任意のパスワード"
alert_email            = "通知先メール（任意）"
```

**.secrets/credentials.yml:**

```bash
mkdir -p .secrets
cat > .secrets/credentials.yml << 'EOF'
---
rcon_password: "prod.tfvarsと同じパスワード"
EOF
chmod 600 .secrets/credentials.yml
```

## 2. デプロイ

### 2.1 環境変数を設定

毎回ターミナルを開くたびに必要：

```bash
export AWS_PROFILE=minecraft-prod
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES  # macOS のみ
```

### 2.2 Lambda Layer をビルド

初回と discord-bot/requirements.txt 変更時：

```bash
./scripts/build-lambda-layer.sh
```

### 2.3 インフラを構築（OpenTofu）

```bash
cd tofu
tofu init
tofu plan -var-file=environments/prod.tfvars
tofu apply -var-file=environments/prod.tfvars
cd ..
```

### 2.4 Ansible 用設定を同期

```bash
./scripts/sync_infra.sh
```

### 2.5 サーバーをセットアップ（Ansible）

```bash
cd ansible
ansible-playbook playbooks/setup.yml
ansible-playbook playbooks/deploy.yml
cd ..
```

### 2.6 Discord コマンドを登録

```bash
export DISCORD_APPLICATION_ID="あなたのApplication ID"
export DISCORD_BOT_TOKEN="あなたのBot Token"
./scripts/register-discord-commands.sh
```

### 2.7 Discord に Endpoint URL を設定

1. `tofu output discord_bot_function_url` で URL を確認
2. Discord Developer Portal → General Information
3. INTERACTIONS ENDPOINT URL に URL を貼り付け
4. Save Changes

## 3. 日常の運用コマンド

### 環境変数（毎回必要）

```bash
export AWS_PROFILE=minecraft-prod
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES  # macOS
```

### 状態確認

```bash
cd tofu && tofu output
```

### EC2 に SSM 接続

```bash
INSTANCE_ID=$(cd tofu && tofu output -raw instance_id)
aws ssm start-session --target $INSTANCE_ID
```

### インフラ変更を適用

```bash
cd tofu
tofu plan -var-file=environments/prod.tfvars
tofu apply -var-file=environments/prod.tfvars
cd ..
./scripts/sync_infra.sh  # Ansible 設定を同期
```

### Ansible Playbook を実行

```bash
cd ansible

# セットアップ（Docker等のインストール）
ansible-playbook playbooks/setup.yml

# Minecraft デプロイ
ansible-playbook playbooks/deploy.yml

# 手動起動
ansible-playbook playbooks/start.yml

# 手動停止
ansible-playbook playbooks/stop.yml

# 手動バックアップ
ansible-playbook playbooks/backup.yml
```

### Lambda ログを確認

```bash
aws logs tail /aws/lambda/minecraft-prod-discord-bot --follow
```

### 全リソースを削除

```bash
cd tofu
tofu destroy -var-file=environments/prod.tfvars
```

## 4. トラブルシューティング

### 「credentials が見つからない」

```bash
export AWS_PROFILE=minecraft-prod
```

### Ansible で fork エラー（macOS）

```bash
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
```

### SSM 接続できない

- EC2 起動後 3-5 分待つ
- `aws ssm describe-instance-information --profile minecraft-prod` で確認

### Discord コマンドが表示されない

- 登録後、最大1時間かかることがある
- `register-discord-commands.sh` を再実行