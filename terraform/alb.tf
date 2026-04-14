# ---------------------------------------------------------
# Application Load Balancer (ALB)
# - Public Subnets に配置
# - ALB SG を適用
# ---------------------------------------------------------
resource "aws_lb" "alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  subnets = [
    aws_subnet.public_a.id,
    aws_subnet.public_c.id
  ]

  tags = {
    Name = "web-alb"
  }
}
