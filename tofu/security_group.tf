# --------------------------------------------
# Minecraft Server 用 Security Group
# --------------------------------------------
resource "aws_security_group" "minecraft" {
  name        = "${local.name_prefix}-minecraft-sg"
  description = "Security group for Minecraft server"
  vpc_id      = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-minecraft-sg"
  })
}

# --------------------------------------------
# Ingress ルール: Minecraft ポート (25565)
# --------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "minecraft_game" {
  security_group_id = aws_security_group.minecraft.id
  description       = "Minecraft game port"
  from_port         = 25565
  to_port           = 25565
  ip_protocol       = "tcp"

  # 全ての IP アドレスからのアクセスを許可
  cidr_ipv4 = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-minecraft-game"
  }
}

# --------------------------------------------
# Ingress ルール: Geyser ポート (19132)
# --------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "minecraft_geyser" {
  security_group_id = aws_security_group.minecraft.id
  description       = "Geyser port for Bedrock clients"
  from_port         = 19132
  to_port           = 19132
  ip_protocol       = "udp"    # ← TCPではなくUDP、ここが重要

  cidr_ipv4 = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-minecraft-geyser"
  }
}

# --------------------------------------------
# Ingress ルール: RCON ポート (25575)
# --------------------------------------------
resource "aws_vpc_security_group_ingress_rule" "minecraft_rcon" {
  security_group_id = aws_security_group.minecraft.id

  description = "Minecraft RCON port (internal only)"
  from_port   = 25575
  to_port     = 25575
  ip_protocol = "tcp"

  # VPC 内部からのみアクセス許可
  cidr_ipv4 = var.vpc_cidr

  tags = {
    Name = "${local.name_prefix}-minecraft-rcon"
  }
}

# --------------------------------------------
# Egress ルール: 全ての外向き通信を許可
# --------------------------------------------
resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.minecraft.id

  description = "Allow all outbound traffic"
  ip_protocol = "-1" # 全てのプロトコル

  cidr_ipv4 = "0.0.0.0/0"

  tags = {
    Name = "${local.name_prefix}-allow-all-outbound"
  }
}