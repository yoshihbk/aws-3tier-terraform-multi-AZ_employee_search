# - Security Group for ALB
# - インターネット公開用の ALB に適用する SG
# - HTTP/HTTPS を全世界から受け付ける（外部公開のため）
# - EC2 へは ALB からのみ通信を許可するゼロトラスト設計の前提となる
# ---------------------------------------------------------
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.main.id

  # -------------------------------------------------------
  # Inbound Rules
  # - ALB は外部公開のため 80/443 を全世界から受け付ける
  # - ただし EC2 側は ALB からの通信しか受け付けないため安全
  # - ゼロトラスト設計の前提として、ALB → EC2 の通信以外は全て拒否する
  # HTTP (80)
  ingress {
    description = "Allow HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (443)
  ingress {
    description = "Allow HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # -------------------------------------------------------
  # Outbound Rules
  # - ALB → EC2 への通信は ALB が自動で行うため全許可で問題なし
  # - ALB は基本的に外向き通信を制限する必要がない
  # -------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.default_tags,
    { Name = "alb-sg" }
  )
}

# ---------------------------------------------------------
# Security Group for EC2 (Web/App)
# - アプリケーションサーバー用の SG
# - インターネットからの直接アクセスは禁止（ゼロトラスト）
# - ALB からの HTTP(80) のみ受け付ける
# - SSH(22) は不要（SSM Session Manager を使用するため）
# ---------------------------------------------------------
resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Security Group for EC2 instances"
  vpc_id      = aws_vpc.main.id

  # -------------------------------------------------------
  # Inbound Rules
  # - EC2 は ALB からの HTTP(80) のみ許可
  # - インターネットからの直接アクセスは完全拒否
  # - SSH(22) も開けない（SSM Session Manager を利用）
  # -------------------------------------------------------
  ingress {
    description     = "Allow HTTP from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB SG のみ許可
  }

  # -------------------------------------------------------
  # Outbound Rules
  # - EC2 → 外部通信は NAT Gateway 経由で行うため全許可で問題なし
  # - OS アップデートやパッケージ取得などの外部通信が必要
  # -------------------------------------------------------
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.default_tags,
    { Name = "ec2-sg" }
  )
}
