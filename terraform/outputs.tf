# ---------------------------------------------------------
# Outputs
# ---------------------------------------------------------

# ALB の DNS 名（ブラウザでアクセスするため）
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

# ASG 名（デバッグ用）
output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

# Launch Template ID（デバッグ用）
output "launch_template_id" {
  value = aws_launch_template.web_lt.id
}
