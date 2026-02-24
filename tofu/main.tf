# --------------------------------------------
# Terraform/OpenTofu の設定
# --------------------------------------------

terraform {
    required_version = ">= 1.6.0"

    required_providers {
        # これによりopentofuでawsと話せる
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }

        random = {
            source = "hashicorp/random"
            version = "~> 3.0"
        }
    }

    # tfstate の保存先（後で S3 に変更可能）
    # backend "s3" {
    #   bucket = "your-tfstate-bucket"
    #   key    = "minecraft/terraform.tfstate"
    #   region = "ap-northeast-1"
}

# --------------------------------------------
# AWS プロバイダ設定
# --------------------------------------------

provider "aws" {
    region = var.aws_region

    # LocalStack 用の設定
    # var.environment が "local" の場合のみ適用（block定義にif文が使えないから'dynamic'）

    dynamic "endpoints" {
        for_each = var.environment == "local" ? [1] : []
        content {
            # 全てのサービスを localhost:4566 に向ける
            s3         = var.localstack_endpoint
            ec2        = var.localstack_endpoint
            iam        = var.localstack_endpoint
            lambda     = var.localstack_endpoint
            apigateway = var.localstack_endpoint
            ssm        = var.localstack_endpoint
            sts        = var.localstack_endpoint
        }
    }

    # LocalStack の場合は認証をスキップ
    skip_credentials_validation = var.environment == "local"
    skip_metadata_api_check = var.environment == "local"
    skip_requesting_account_id = var.environment == "local"

    # LocalStack の場合は S3 のパススタイルを使用
    # (通常は bucket.s3.amazonaws.com だが、LocalStack は localhost:4566/bucket)
    s3_use_path_style = var.environment == "local"

    # デフォルトのタグ（全リソースに自動付与）
    default_tags {
        tags = {
            Project     = var.project_name
            Environment = var.environment
            ManagedBy   = "OpenTofu"
        }
  }
}