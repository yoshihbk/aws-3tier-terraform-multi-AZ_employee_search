# Public Subnet (ap-northeast-1a)
# - インターネット公開用リソース（ALBなど）を配置
# - map_public_ip_on_launch = true により EC2 に自動で Public IP を付与
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  # -------------------------------------------------------
  # タグ（統一タグ + リソース固有タグ）
  # - default_tags は terraform.tfvars で定義
  # - merge により共通タグと Name タグを統合
  # -------------------------------------------------------
  tags = merge(
    var.default_tags,
    { Name = "public-subnet-1a" }
  )
}

# ---------------------------------------------------------
# Public Subnet (ap-northeast-1c)
# - 1a と同じ役割の Public Subnet を別 AZ に配置（冗長化）
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = merge(
    var.default_tags,
    { Name = "public-subnet-1c" }
  )
}

# ---------------------------------------------------------
# Private Subnet (ap-northeast-1a)
# - アプリケーションサーバーや RDS を配置する内部用サブネット
# - インターネットから直接アクセスされない
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = merge(
    var.default_tags,
    { Name = "private-subnet-1a" }
  )
}

# ---------------------------------------------------------
# Private Subnet (ap-northeast-1c)
# - 1a と同じ役割の Private Subnet を別 AZ に配置（冗長化）
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"

  tags = merge(
    var.default_tags,
    { Name = "private-subnet-1c" }
  )
}
