# ---------------------------------------------------------
# RDS Security Group
# - EC2 からの MySQL (3306) を許可
# ---------------------------------------------------------
resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Allow MySQL from EC2"
  vpc_id      = aws_vpc.main.id

  # EC2 → RDS の 3306 を許可
  ingress {
    description = "MySQL from EC2"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [
      aws_security_group.ec2_sg.id
    ]
  }

  # RDS → 外部への通信（更新など）は許可
  egress {
    from_port = 0
    to_port   = 0
    # 全てのプロトコルを許可（RDSは複数のプロトコルを使用するため、-1で全てのプロトコルを指定）
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "rds-sg"
  }
}
