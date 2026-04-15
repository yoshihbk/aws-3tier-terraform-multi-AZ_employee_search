# ---------------------------------------------------------
# Public Subnet (ap-northeast-1a)
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1a"
  }
}

# ---------------------------------------------------------
# Public Subnet (ap-northeast-1c)
# ---------------------------------------------------------
resource "aws_subnet" "public_subnet_1c" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet-1c"
  }
}

# ---------------------------------------------------------
# Private Subnet (ap-northeast-1a)
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
# ---------------------------------------------------------
resource "aws_subnet" "private_subnet_1c" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "ap-northeast-1c"

  tags = {
    Name = "private-subnet-1c"
  }
}
