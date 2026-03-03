#!/bin/bash
# ============================================
# Discord スラッシュコマンド登録スクリプト
# ============================================

set -e

# 設定（環境変数または直接指定）
DISCORD_APPLICATION_ID="${DISCORD_APPLICATION_ID:-YOUR_APPLICATION_ID}"
DISCORD_BOT_TOKEN="${DISCORD_BOT_TOKEN:-YOUR_BOT_TOKEN}"

# API エンドポイント
API_URL="https://discord.com/api/v10/applications/${DISCORD_APPLICATION_ID}/commands"

# コマンド定義
COMMANDS='[
  {
    "name": "server",
    "description": "Minecraft サーバーを管理します",
    "options": [
      {
        "name": "start",
        "description": "サーバーを起動します",
        "type": 1
      },
      {
        "name": "stop",
        "description": "サーバーを停止します",
        "type": 1
      },
      {
        "name": "status",
        "description": "サーバーの状態を確認します",
        "type": 1
      },
      {
        "name": "backup",
        "description": "バックアップを作成します",
        "type": 1
      },
      {
        "name": "logs",
        "description": "サーバーログを表示します",
        "type": 1,
        "options": [
          {
            "name": "lines",
            "description": "表示する行数（デフォルト: 10、最大: 30）",
            "type": 4,
            "required": false
          }
        ]
      }
    ]
  }
]'

echo "Discord コマンドを登録しています..."

# API リクエスト
response=$(curl -s -X PUT \
  -H "Authorization: Bot ${DISCORD_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "${COMMANDS}" \
  "${API_URL}")

echo "レスポンス:"
echo "${response}" | jq .

echo "コマンド登録が完了しました"