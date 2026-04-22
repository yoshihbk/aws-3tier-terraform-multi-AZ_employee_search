# ---------------------------------------------------------
# Application Load Balancer (ALB)
# - Public Subnets に配置
# - ALB SG を適用
# ---------------------------------------------------------
resource "aws_lb" "alb" {
  name               = "web-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]

  # ALB を配置するサブネット（public 1a / 1c）
  subnets = [
    aws_subnet.public_subnet_1a.id,
    aws_subnet.public_subnet_1c.id
  ]

  tags = {
    Name = "web-alb"
  }
}
# ---------------------------------------------------------
# Target Group for ALB
# - EC2 (Web/App) をぶら下げる入口
# ---------------------------------------------------------
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path = "/"
    port = "80"
  }

  tags = {
    Name = "web-tg"
  }
}

resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}
