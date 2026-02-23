# --------------------------------------------
# VPC
# --------------------------------------------

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # DNS設定（EC2がDNS名を持てるようにする）
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

# --------------------------------------------
# Internet Gateway
# --------------------------------------------
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-igw"
  })
}

# --------------------------------------------
# Public Subnet
# --------------------------------------------
resource "aws_subnet" "public" {
  vpc_id = aws_vpc.main.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.availability_zone

  # このサブネットで起動したEC2に自動でパブリックIPを付与
  map_public_ip_on_launch = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-subnet"
    Type = "Public"
  })
}

# --------------------------------------------
# Route Table（ルートテーブル）
# --------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # デフォルトルート: 0.0.0.0/0（全ての宛先）をIGWに向ける
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-public-rt"
  })
}

# --------------------------------------------
# Route Table Association（関連付け）
# --------------------------------------------
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}