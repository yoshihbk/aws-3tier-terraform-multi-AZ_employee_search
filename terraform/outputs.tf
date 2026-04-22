# Outputs
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

# ---------------------------------------------------------
# RDS Endpoint 出力
# - EC2 からMySQLに接続するためのホスト名
# ---------------------------------------------------------
output "rds_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.database.address
}

# ---------------------------------------------------------
# RDS Port 出力
# - MySQL の接続ポート（通常 3306）
# ---------------------------------------------------------
output "rds_port" {
  description = "RDS MySQL port"
  value       = aws_db_instance.database.port
}
