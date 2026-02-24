# --------------------------------------------
# 最新の Amazon Linux 2023 AMI を取得
# --------------------------------------------
data "aws_ami" "amazon_linux_2023" {
    most_recent = true
    owners = ["amazon"]

    filter {
      name = "name"
      values = ["al2023-ami-*-x86_64"]
    }

    filter {
      name = "virtualization-type"
      values = ["hvm"]
    }
}

# --------------------------------------------
# EC2 インスタンス
# --------------------------------------------
resource "aws_instance" "minecraft" {
  # AMI(OSイメージ)
  ami = data.aws_ami.amazon_linux_2023.id
  
  # インスタンスタイプ（スペック）
  instance_type = var.instance_type

  # 配置先サブネット
  subnet_id = aws_subnet.public.id

  # セキュリティグループ
  vpc_security_group_ids = [aws_security_group.minecraft.id]
  
  # IAM ロール（後で定義）
  iam_instance_profile = aws_iam_instance_profile.minecraft.name

  # EBS（ストレージ）設定
  root_block_device {
    volume_type = "gp3"
    volume_size = var.volume_size
    delete_on_termination = true
    encrypted = true

    tags = merge(local.minecraft_tags, {
      Name = "${local.name_prefix}-ebs"
    })
  }

  # User Data: インスタンス起動時に実行されるスクリプト
  user_data = base64encode(<<-EOF
    #!/bin/bash
    # ログ出力先を設定
    exec > >(tee /var/log/user-data.log) 2>&1
    echo "=== User Data Script Started ==="

    # システムアップデート
    dnf update -y

    # Docker インストール
    dnf install -y docker
    systemctl enable docker
    systemctl start docker

    # Docker Compose インストール
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # ec2-user を docker グループに追加
    usermod -aG docker ec2-user

    # Minecraft 用ディレクトリ作成
    mkdir -p /opt/minecraft
    chown ec2-user:ec2-user /opt/minecraft

    echo "=== User Data Script Completed ==="
  EOF
  )

  # インスタンスの詳細モニタリング
  monitoring = false

  # インスタンスメタデータサービス v2 を必須
  metadata_options {
    http_endpoint = "enabled"
    http_tokens = "required"
    http_put_response_hop_limit = 1
  }

  tags = merge(local.minecraft_tags, {
    Name = "${local.name_prefix}-server"
  })

  lifecycle {
    ignore_changes = [ami]  # AMI の更新は無視（意図しない再作成を防ぐ）
  }
}

# --------------------------------------------
# Elastic IP
# --------------------------------------------

resource "aws_eip" "minecraft" {
  domain = "vpc"

  tags = merge(local.minecraft_tags, {
    Name = "${local.name_prefix}-eip"
  })
}

# --------------------------------------------
# EIP を EC2 に関連付け
# --------------------------------------------
resource "aws_eip_association" "minecraft" {
  instance_id = aws_instance.minecraft.id
  allocation_id = aws_eip.minecraft.id
}