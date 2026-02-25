# --------------------------------------------
# VPC 関連
# --------------------------------------------

output "vpc_id" {
  description = "作成された VPC の ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "パブリックサブネットの ID"
  value       = aws_subnet.public.id
}

# --------------------------------------------
# EC2 関連
# --------------------------------------------

output "instance_id" {
  description = "EC2 インスタンスの ID"
  value       = aws_instance.minecraft.id
}

output "instance_private_ip" {
  description = "EC2 のプライベート IP アドレス"
  value       = aws_instance.minecraft.private_ip
}

output "elastic_ip" {
  description = "Elastic IP アドレス"
  value       = aws_eip.minecraft.public_ip
}

output "minecraft_address" {
  description = "Minecraft サーバーの接続先"
  value       = "${aws_eip.minecraft.public_ip}:25565"
}

# --------------------------------------------
# Security Group 関連
# --------------------------------------------

output "security_group_id" {
  description = "Minecraft 用セキュリティグループの ID"
  value       = aws_security_group.minecraft.id
}

# --------------------------------------------
# S3 関連
# --------------------------------------------

output "backup_bucket_name" {
  description = "バックアップ用 S3 バケット名"
  value       = aws_s3_bucket.backup.id
}

output "backup_bucket_arn" {
  description = "バックアップ用 S3 バケットの ARN"
  value       = aws_s3_bucket.backup.arn
}

# --------------------------------------------
# IAM 関連
# --------------------------------------------

output "iam_role_name" {
  description = "EC2 用 IAM ロール名"
  value       = aws_iam_role.minecraft.name
}

output "iam_role_arn" {
  description = "EC2 用 IAM ロールの ARN"
  value       = aws_iam_role.minecraft.arn
}

# --------------------------------------------
# 便利な出力
# --------------------------------------------

output "ssm_connect_command" {
  description = "SSM でインスタンスに接続するコマンド"
  value       = "aws ssm start-session --target ${aws_instance.minecraft.id}"
}