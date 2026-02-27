#!/bin/bash
# OpenTofu の output を Ansible の host_vars に自動反映するスクリプト

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOFU_DIR="${SCRIPT_DIR}/../tofu"
HOST_VARS_FILE="${SCRIPT_DIR}/../ansible/inventory/host_vars/minecraft-server.yml"

cd "${TOFU_DIR}"

TOFU_OUTPUT=$(tofu output -json)

INSTANCE_ID=$(echo "${TOFU_OUTPUT}"      | jq -r '.instance_id.value')
BACKUP_BUCKET=$(echo "${TOFU_OUTPUT}"    | jq -r '.backup_bucket_name.value')
SSM_BUCKET=$(echo "${TOFU_OUTPUT}"       | jq -r '.ssm_bucket_name.value')
ELASTIC_IP=$(echo "${TOFU_OUTPUT}"       | jq -r '.elastic_ip.value')

cat > "${HOST_VARS_FILE}" << EOF
---
# 生成日時: $(date '+%Y-%m-%d %H:%M:%S')

ec2_instance_id: "${INSTANCE_ID}"
ssm_bucket_name: "${SSM_BUCKET}"
backup_s3_bucket: "${BACKUP_BUCKET}"
aws_region: "ap-northeast-1"
elastic_ip: "${ELASTIC_IP}"
# RCON パスワードは Ansible Vault で暗号化
rcon_password: "{{ vault_rcon_password }}"
EOF

echo ""
echo "host_vars を更新しました: ${HOST_VARS_FILE}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  instance_id   : ${INSTANCE_ID}"
echo "  ssm_bucket    : ${SSM_BUCKET}"
echo "  backup_bucket : ${BACKUP_BUCKET}"
echo "  elastic_ip    : ${ELASTIC_IP}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""