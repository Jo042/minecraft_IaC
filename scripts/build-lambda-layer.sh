#!/bin/bash
# ============================================
# Lambda Layer のビルドスクリプト
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DISCORD_BOT_DIR="${PROJECT_ROOT}/discord-bot"
LAYER_DIR="${DISCORD_BOT_DIR}/layer"
DIST_DIR="${DISCORD_BOT_DIR}/dist"

echo "🔧 Lambda Layer をビルドしています..."

# クリーンアップ
rm -rf "${LAYER_DIR}"
rm -rf "${DIST_DIR}"
mkdir -p "${LAYER_DIR}/python"
mkdir -p "${DIST_DIR}"

echo "依存パッケージをインストール中..."
pip install \
    --platform manylinux2014_x86_64 \
    --target "${LAYER_DIR}/python" \
    --implementation cp \
    --python-version 3.11 \
    --only-binary=:all: \
    -r "${DISCORD_BOT_DIR}/requirements.txt"

echo "ZIP ファイルを作成中..."
cd "${LAYER_DIR}"
zip -r "${DIST_DIR}/lambda_layer.zip" .

echo "Lambda Layer のビルドが完了しました"
echo "   ${DIST_DIR}/lambda_layer.zip"