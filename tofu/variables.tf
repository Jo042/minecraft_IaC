# --------------------------------------------
# 基本設定
# --------------------------------------------
variable "project_name" {
  description = "test_craft"
  type = string
  default = "minecraft"
}

variable "environment" {
  description = "環境名(local / prod)"
  type = string
  default = "local"

  validation {
    condition = contains(["local", "prod"], var.environment)
    error_message = "environmentは 'local' または 'prod' である必要があります"
  }
}

variable "aws_region" {
  description = "AWSリージョン"
  type =  string
  default = "ap-northeast-1"
}

# --------------------------------------------
# LocalStack 設定
# --------------------------------------------
variable "localstack_endpoint" {
  description = "LocalStack のエンドポイント"
  type = string
  default = "http://localhost:4566"
}


# --------------------------------------------
# ネットワーク設定
# --------------------------------------------
variable "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  type = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "パブリックサブネットの CIDR ブロック"
  type = string
  default = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "使用するアベイラビリティゾーン"
  type = string
  default = "ap-northeast-1a"
}

# --------------------------------------------
# EC2 設定
# --------------------------------------------

variable "instance_type" {
  description = "EC2 インスタンスタイプ"
  type = string
  default = "t3.medium"
}

variable "volume_size" {
  description = "EBS ボリュームサイズ(GB)"
  type = number
  default = 30
}

variable "key_name" {
  description = "SSH キーペア名"
  type = string
  default = ""
}

# --------------------------------------------
# Minecraft 設定
# --------------------------------------------
variable "minecraft_version" {
  description = "Minecraft サーバーのバージョン"
  type        = string
  default     = "1.21.4"
}

variable "minecraft_memory" {
  description = "Minecraft に割り当てるメモリ"
  type        = string
  default     = "4G"
}

variable "rcon_password" {
  description = "RCON パスワード"
  type        = string
  sensitive   = true  # ログに出力されない
  default     = ""
}

# --------------------------------------------
# S3 設定
# --------------------------------------------
variable "backup_retention_days" {
  description = "バックアップの保持日数"
  type        = number
  default     = 30
}