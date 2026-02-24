# --------------------------------------------
# EC2 用 IAM ロール
# --------------------------------------------

resource "aws_iam_role" "minecraft" {
  name = "${local.name_prefix}--ec2-role"

  # Trust Policy（誰がこのロールを使えか）
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = {
                Service = "ec2.amazonaws.com"
            }
        }
    ]
  })
  tags = local.common_tags
}


# --------------------------------------------
# S3 バックアップ用ポリシー
# --------------------------------------------
resource "aws_iam_role_policy" "name" {
  name = "${local.name_prefix}-s3-backup-policy"
  role = aws_iam_role.minecraft.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowS3BucketOperations"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.backup.arn
      },
      {
        Sid    = "AllowS3ObjectOperations"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListMultipartUploadParts",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${aws_s3_bucket.backup.arn}/*"
      }
    ]
  })
}

# --------------------------------------------
# SSM 用マネージドポリシーをアタッチ
# --------------------------------------------
resource "aws_iam_role_policy_attachment" "ssm" {
  role = aws_iam_role.minecraft.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


# --------------------------------------------
# CloudWatch Logs 用ポリシー
# --------------------------------------------
resource "aws_iam_role_policy" "name" {
  name = "${local.name_prefix}-cloudwatch-logs-policy"
  role = aws_iam_role.minecraft.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}


# --------------------------------------------
# インスタンスプロファイル
# --------------------------------------------
resource "aws_iam_instance_profile" "minecraft" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.minecraft.name

  tags = local.common_tags
}