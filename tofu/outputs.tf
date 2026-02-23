# --------------------------------------------
# VPC 関連
# --------------------------------------------

output "vpc_id" {
  description = "作成された VPC の ID"
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC の CIDR ブロック"
  value = aws_vpc.main.cidr_block
}

output "public_subnet_id" {
  description = "パブリックサブネットの ID"
  value = aws_subnet.public.id
}

# --------------------------------------------
# EC2 関連（後で追加）
# --------------------------------------------

# output "instance_id" {
#   description = "EC2 インスタンスの ID"
#   value = aws_instance.minecraft.id
# }

# output "public_ip" {
#   description = "EC2 のパブリック IP アドレス"
#   value = aws_eip.minecraft.public_ip
# }

# output "minecraft_address" {
#   description = "Minecraft サーバーの接続先"
#   value = "${aws_eip.minecraft.public_ip}:25565"
# }

# --------------------------------------------
# S3 関連（後で追加）
# --------------------------------------------

# output "backup_bucket_name" {
#   description = "バックアップ用 S3 バケット名"
#   value = aws_s3_bucket.backup.id
# }
