# --------------------------------------------
# ランダムな文字列を生成（バケット名のサフィックス）
# --------------------------------------------

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# --------------------------------------------
# バックアップ用 S3 バケット
# --------------------------------------------
resource "aws_s3_bucket" "backup" {
  bucket = "${local.name_prefix}-backup-${random_id.bucket_suffix.hex}"

  # バケット削除時の挙動
  force_destroy = var.environment == "local"

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-backup"
    Purpose = "Minecraft world backup"
  })
}

# --------------------------------------------
# バケットのバージョニング設定(同じファイル名で上書きしても、古いバージョンが残る)
# --------------------------------------------
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# --------------------------------------------
# バケットのライフサイクルルール
# --------------------------------------------
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "expire-old-backups"
    status = "Enabled"

    expiration {
      days = var.backup_retention_days
    }

    filter {
      prefix = "backup/"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.backup_retention_days
    }
  }
}

# --------------------------------------------
# パブリックアクセスのブロック
# --------------------------------------------
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket = aws_s3_bucket.backup.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --------------------------------------------
# サーバーサイド暗号化の設定
# --------------------------------------------
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}