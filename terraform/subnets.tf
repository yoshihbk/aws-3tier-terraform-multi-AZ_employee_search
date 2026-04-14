# ---------------------------------------------------------
# Public Subnet (ap-northeast-1a)
# - ALB や NAT Gateway を配置する公開サブネット
# - インターネットと直接通信可能
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "public-subnet-1a"
  }
}

# ---------------------------------------------------------
# Public Subnet (ap-northeast-1c)
# - Multi-AZ のための 2 つ目の公開サブネット
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "public-subnet-1c"
  }
}

# ---------------------------------------------------------
# Private Subnet (ap-northeast-1a)
# - EC2（アプリ層）や RDS を配置する非公開サブネット
# - インターネットへは NAT Gateway 経由で通信
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"

  tags = {
    Name = "private-subnet-1a"
  }
}

# ---------------------------------------------------------
# Private Subnet (ap-northeast-1c)
# - Multi-AZ のための 2 つ目の非公開サブネット
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "private-subnet-1c"
  }
}
