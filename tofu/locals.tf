# 【locals と variable の違い】
# variable: 外部から値を渡す（tfvars ファイルや -var オプション）
# locals:   内部で計算・加工した値を定義

locals {
    name_prefix = "${var.project_name}-${var.environment}"

    # 共通タグ
    common_tags = {
        Project = var.project_name
        Environment = var.environment
        ManagedBy = "OpenTofu"
    }

    # Minecraft用タグ
    minecraft_tags = merge(local.common_tags, {
        Application = "Minecraft"
        Version = var.minecraft_version
    })

    # 現在のAWSアカウントID（本番環境用）
    # LocalStack では使用しない
    # account_id = data.aws_caller_identity.current.account_id
}

# 現在のAWSアカウント情報を取得（本番環境用）
# data "aws_caller_identity" "current" {
#   count = var.environment == "prod" ? 1 : 0
# }