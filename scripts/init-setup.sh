#!/bin/bash
# ============================================
# 初期設定スクリプト
# clone 後に最初に実行するスクリプト
# ============================================

set -e

# 色付け
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${GREEN}Minecraft Server IaC 初期設定${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# 前提条件チェック
# ============================================
echo -e "${BLUE}前提条件をチェック中...${NC}"

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 がインストールされていません${NC}"
        echo "   インストール方法: $2"
        exit 1
    else
        echo -e "   $1"
    fi
}

check_command "aws" "https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
check_command "tofu" "brew install opentofu"
check_command "ansible" "pip install ansible"
check_command "jq" "brew install jq"
check_command "python3" "brew install python3"

echo ""

# ============================================
# AWS プロファイル確認
# ============================================
echo -e "${BLUE}AWS 設定${NC}"
echo ""

if aws configure list --profile minecraft-prod &> /dev/null; then
    echo -e "   AWS プロファイル 'minecraft-prod' が設定済み"
else
    echo -e "${YELLOW}⚠️ AWS プロファイル 'minecraft-prod' が見つかりません${NC}"
    echo ""
    echo "AWS CLI で設定してください:"
    echo "  aws configure --profile minecraft-prod"
    echo ""
    read -p "設定しましたか？ (y/n): " aws_configured
    if [ "$aws_configured" != "y" ]; then
        echo "AWS プロファイルを設定してから再実行してください"
        exit 1
    fi
fi

# リージョン確認
AWS_REGION=$(aws configure get region --profile minecraft-prod 2>/dev/null || echo "")
if [ -z "$AWS_REGION" ]; then
    read -p "AWS リージョン [ap-northeast-1]: " AWS_REGION
    AWS_REGION=${AWS_REGION:-ap-northeast-1}
else
    echo -e "  リージョン: ${AWS_REGION}"
fi

echo ""

# ============================================
# Discord 設定
# ============================================
echo -e "${BLUE}Discord 設定${NC}"
echo ""
echo "Discord Developer Portal でアプリを作成してください:"
echo -e "  ${BLUE}https://discord.com/developers/applications${NC}"
echo ""
echo "詳細な手順は docs/discord-setup.md を参照してください"
echo ""

read -p "Discord Application ID: " DISCORD_APP_ID
read -p "Discord Public Key: " DISCORD_PUBLIC_KEY
read -sp "Discord Bot Token（非表示）: " DISCORD_BOT_TOKEN
echo ""
echo ""

# ============================================
# Minecraft 設定
# ============================================
echo -e "${BLUE}Minecraft 設定${NC}"
echo ""

read -p "RCON パスワード（サーバー管理用、任意の文字列）: " RCON_PASSWORD
if [ -z "$RCON_PASSWORD" ]; then
    RCON_PASSWORD=$(openssl rand -base64 12)
    echo -e "  自動生成: ${RCON_PASSWORD}"
fi

read -p "アラート通知メール（任意、空欄でスキップ）: " ALERT_EMAIL

echo ""

# ============================================
# 設定ファイル生成
# ============================================
echo -e "${BLUE}設定ファイルを生成中...${NC}"

# .secrets ディレクトリ
mkdir -p .secrets

# credentials.yml
cat > .secrets/credentials.yml << EOF
---
# 自動生成: $(date '+%Y-%m-%d %H:%M:%S')
# このファイルは .gitignore に含まれています
# 絶対に Git にコミットしないでください！

rcon_password: "${RCON_PASSWORD}"
EOF
chmod 600 .secrets/credentials.yml
echo -e "   .secrets/credentials.yml"

# Discord 設定（コマンド登録用）
cat > .secrets/discord.env << EOF
# Discord 設定（コマンド登録用）
export DISCORD_APPLICATION_ID="${DISCORD_APP_ID}"
export DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN}"
EOF
chmod 600 .secrets/discord.env
echo -e "   .secrets/discord.env"

# prod.tfvars
cat > tofu/environments/prod.tfvars << EOF
# 自動生成: $(date '+%Y-%m-%d %H:%M:%S')

# 基本設定
project_name = "minecraft"
environment  = "prod"
aws_region   = "${AWS_REGION}"

# ネットワーク
vpc_cidr           = "10.0.0.0/16"
public_subnet_cidr = "10.0.1.0/24"
availability_zone  = "${AWS_REGION}a"

# EC2
instance_type = "t3.medium"
volume_size   = 30

# Minecraft
minecraft_version = "1.21.4"
minecraft_memory  = "4G"
minecraft_port    = 25565
rcon_password     = "${RCON_PASSWORD}"

# Discord Bot
discord_public_key     = "${DISCORD_PUBLIC_KEY}"
discord_application_id = "${DISCORD_APP_ID}"

# アラート
alert_email             = "${ALERT_EMAIL}"
billing_alert_threshold = 50
EOF
echo -e "   tofu/environments/prod.tfvars"

echo ""

# ============================================
# Python 環境
# ============================================
echo -e "${BLUE}Python 環境をセットアップ中...${NC}"

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

source venv/bin/activate
pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
echo -e "   Python 仮想環境"

# Ansible コレクション
cd ansible
ansible-galaxy collection install -r requirements.yml --force > /dev/null 2>&1
cd ..
echo -e "   Ansible コレクション"

echo ""

# ============================================
# 完了
# ============================================
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}完了しました${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "次のステップ:"
echo ""
echo -e "  ${BLUE}1. サーバーをデプロイ${NC}"
echo "     make deploy"
echo ""
echo -e "  ${BLUE}2. Discord コマンドを登録${NC}"
echo "     source .secrets/discord.env"
echo "     make discord-setup"
echo ""
echo -e "  ${BLUE}3. Discord で動作確認${NC}"
echo "     /server status"
echo ""
echo "詳細は README.md を参照してください"
echo ""