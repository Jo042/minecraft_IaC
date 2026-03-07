# ============================================
# Minecraft Server IaC - Makefile
# ============================================
#
# 使い方: make <コマンド>
# ヘルプ: make help
#

# シェル設定
SHELL := /bin/bash
.ONESHELL:

# 環境変数
export AWS_PROFILE ?= minecraft-prod
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY ?= YES

# ディレクトリ
TOFU_DIR := tofu
ANSIBLE_DIR := ansible
SCRIPTS_DIR := scripts

# 色付け
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m

# ============================================
# メインコマンド（よく使うもの）
# ============================================

.PHONY: init
init: ## 初期設定（最初に1回実行）
	@echo -e "$(GREEN)初期設定を開始します...$(NC)"
	@./$(SCRIPTS_DIR)/init-setup.sh

.PHONY: deploy
deploy: _check-secrets _build-layer _tofu-apply _sync-infra _ansible-setup _ansible-deploy ## サーバーをデプロイ
	@echo -e "$(GREEN)デプロイ完了！$(NC)"
	@echo ""
	@echo "次のステップ:"
	@echo "  1. make discord-setup  # Discord コマンド登録"
	@echo "  2. Discord で /server status を実行"

.PHONY: destroy
destroy: ## 全リソースを削除（課金停止）
	@echo -e "$(RED)全てのリソースを削除します$(NC)"
	@read -p "本当に削除しますか？ (yes/no): " confirm && [ "$$confirm" = "yes" ]
	cd $(TOFU_DIR) && tofu destroy -var-file=environments/prod.tfvars -auto-approve
	@echo -e "$(GREEN)削除完了$(NC)"

.PHONY: discord-setup
discord-setup: ## Discord コマンドを登録
	@if [ -z "$$DISCORD_APPLICATION_ID" ] || [ -z "$$DISCORD_BOT_TOKEN" ]; then \
		echo -e "$(RED)環境変数が設定されていません$(NC)"; \
		echo ""; \
		echo "以下を実行してください:"; \
		echo "  export DISCORD_APPLICATION_ID=\"あなたのApplication ID\""; \
		echo "  export DISCORD_BOT_TOKEN=\"あなたのBot Token\""; \
		echo ""; \
		echo "Discord Developer Portal で確認:"; \
		echo "  https://discord.com/developers/applications"; \
		exit 1; \
	fi
	@./$(SCRIPTS_DIR)/register-discord-commands.sh
	@echo ""
	@echo -e "$(GREEN)Discord コマンド登録完了！$(NC)"
	@echo ""
	@echo "Discord Developer Portal で Interactions Endpoint URL を設定してください:"
	@cd $(TOFU_DIR) && tofu output -raw discord_bot_function_url
	@echo ""

# ============================================
# サーバー操作
# ============================================

.PHONY: status
status: ## サーバー状態を確認
	@echo -e "$(GREEN)サーバー状態$(NC)"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@cd $(TOFU_DIR) && tofu output
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "Discord で /server status を実行すると詳細が見れます"

.PHONY: ssh
ssh: ## EC2 に SSM で接続
	@INSTANCE_ID=$$(cd $(TOFU_DIR) && tofu output -raw instance_id) && \
	echo -e "$(GREEN)EC2 に接続中...$(NC)" && \
	aws ssm start-session --target $$INSTANCE_ID

.PHONY: logs
logs: ## Minecraft サーバーのログを表示
	@INSTANCE_ID=$$(cd $(TOFU_DIR) && tofu output -raw instance_id) && \
	aws ssm start-session --target $$INSTANCE_ID \
		--document-name AWS-StartInteractiveCommand \
		--parameters command="docker logs minecraft-server --tail 50 -f"

# ============================================
# 開発・メンテナンス用
# ============================================

.PHONY: plan
plan: ## インフラ変更の確認（dry-run）
	cd $(TOFU_DIR) && tofu plan -var-file=environments/prod.tfvars

.PHONY: apply
apply: _build-layer ## インフラのみ適用（Ansible なし）
	cd $(TOFU_DIR) && tofu apply -var-file=environments/prod.tfvars
	@./$(SCRIPTS_DIR)/sync_infra.sh

.PHONY: ansible-setup
ansible-setup: _sync-infra _ansible-setup ## Ansible setup のみ実行

.PHONY: ansible-deploy
ansible-deploy: _sync-infra _ansible-deploy ## Ansible deploy のみ実行

.PHONY: sync
sync: ## Tofu 出力を Ansible に同期
	@./$(SCRIPTS_DIR)/sync_infra.sh

.PHONY: build-layer
build-layer: _build-layer ## Lambda Layer をビルド

.PHONY: lambda-logs
lambda-logs: ## Lambda のログを表示
	aws logs tail /aws/lambda/minecraft-prod-discord-bot --follow

.PHONY: test
test: ## テストを実行
	cd discord-bot && python -m pytest tests/ -v

# ============================================
# 内部コマンド（直接呼ばない）
# ============================================

.PHONY: _check-secrets
_check-secrets:
	@if [ ! -f ".secrets/credentials.yml" ]; then \
		echo -e "$(RED).secrets/credentials.yml が見つかりません$(NC)"; \
		echo "make init を実行してください"; \
		exit 1; \
	fi
	@if [ ! -f "$(TOFU_DIR)/environments/prod.tfvars" ]; then \
		echo -e "$(RED)tofu/environments/prod.tfvars が見つかりません$(NC)"; \
		echo "make init を実行してください"; \
		exit 1; \
	fi

.PHONY: _build-layer
_build-layer:
	@echo -e "$(GREEN)Lambda Layer をビルド中...$(NC)"
	@./$(SCRIPTS_DIR)/build-lambda-layer.sh

.PHONY: _tofu-apply
_tofu-apply:
	@echo -e "$(GREEN)インフラを構築中...$(NC)"
	cd $(TOFU_DIR) && tofu init -upgrade && tofu apply -var-file=environments/prod.tfvars -auto-approve

.PHONY: _sync-infra
_sync-infra:
	@echo -e "$(GREEN)設定を同期中...$(NC)"
	@./$(SCRIPTS_DIR)/sync_infra.sh

.PHONY: _ansible-setup
_ansible-setup:
	@echo -e "$(GREEN)サーバーをセットアップ中...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/setup.yml

.PHONY: _ansible-deploy
_ansible-deploy:
	@echo -e "$(GREEN)Minecraft をデプロイ中...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook playbooks/deploy.yml

# ============================================
# ヘルプ
# ============================================

.PHONY: help
help: ## ヘルプを表示
	@echo ""
	@echo "Minecraft Server IaC"
	@echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
	@echo ""
	@echo "使い方: make <コマンド>"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo ""

.DEFAULT_GOAL := help