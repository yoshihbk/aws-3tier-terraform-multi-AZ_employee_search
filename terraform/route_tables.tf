# - Internet Gateway (IGW)
# - VPC をインターネットに接続するためのゲートウェイ
# - Public Subnet が外部へ出るために必須
# ---------------------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags,
    { Name = "main-igw" }
  )
}

# ---------------------------------------------------------
# Public Route Table
# - Public Subnet 用のルートテーブル
# - IGW をデフォルトルートに設定することでインターネット接続を実現
# ---------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags,
    { Name = "public-rt" }
  )
}

# ---------------------------------------------------------
# Public Route (0.0.0.0/0 → IGW)
# - Public Subnet の外部通信を IGW にルーティング
# - Public Subnet に配置される ALB や NAT Gateway が外部と通信可能になる---------------------------------------------------------
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# ---------------------------------------------------------
# Route Table Association (public-subnet-1a)
# - Public Subnet (1a) を Public Route Table に紐づける
# - これにより public-subnet-1a の外向き通信は IGW 経由になる
# ---------------------------------------------------------
resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# Route Table Association (public-subnet-1c)
# - Public Subnet (1c) を Public Route Table に紐づける
# - 1a と同様、public-subnet-1c も IGW 経由で外部通信が可能になる
# ---------------------------------------------------------
resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.public_subnet_1c.id
  route_table_id = aws_route_table.public.id
}

# ---------------------------------------------------------
# Elastic IP for NAT Gateway
# - NAT Gateway は固定の Public IP（EIP）が必要
# - Private Subnet の外向き通信の出口として利用される
# ---------------------------------------------------------
resource "aws_eip" "nat_eip" {
  tags = merge(
    var.default_tags,
    { Name = "nat-eip" }
  )
}

# ---------------------------------------------------------
# NAT Gateway (public-subnet-1a)
# - Private Subnet からの外部通信を NAT 経由で行うためのゲートウェイ
# - NAT Gateway は Public Subnet に配置する必要がある（固定IPを持つため）
# ---------------------------------------------------------
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id

  tags = merge(
    var.default_tags,
    { Name = "nat-gateway" }
  )
}

# ---------------------------------------------------------
# Private Route Table
# - Private Subnet 用のルートテーブル
# - 0.0.0.0/0 を NAT Gateway に向けることで外部通信を実現
# - Private Subnet は Public IP を持たないため NAT が必須
# ---------------------------------------------------------
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.default_tags,
    { Name = "private-rt" }
  )
}

# ---------------------------------------------------------
# Private Route (0.0.0.0/0 → NAT Gateway)
# - Private Subnet からインターネットへ出るためのルート
# - NAT Gateway を経由することで外部通信のみ可能（外部からの通信は遮断）
# - アプリ層 EC2 や RDS が安全に外部へアクセスできる
# ---------------------------------------------------------
resource "aws_route" "private_nat_access" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

# ---------------------------------------------------------
# Route Table Association (private-subnet-1a)
# - Private Subnet (1a) を Private Route Table に紐づける
# - この関連付けにより、private-subnet-1a の外向き通信は NAT Gateway 経由になる
# ---------------------------------------------------------
resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_subnet_1a.id
  route_table_id = aws_route_table.private.id
}

# ---------------------------------------------------------
# Route Table Association (private-subnet-1c)
# - Private Subnet (1c) を Private Route Table に紐づける
# - 1a と同様、private-subnet-1c も NAT Gateway 経由で外部通信が可能になる
# ---------------------------------------------------------
resource "aws_route_table_association" "private_1c" {
  subnet_id      = aws_subnet.private_subnet_1c.id
  route_table_id = aws_route_table.private.id
}
