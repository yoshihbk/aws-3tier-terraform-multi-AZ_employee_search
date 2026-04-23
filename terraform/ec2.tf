resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  # RDS が先に必要なので依存関係を明示
  depends_on = [aws_db_instance.database]

  # Amazon Linux 2023
  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = "t2.micro"

  # EC2 のセキュリティグループ
  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  # SSM で入れるように IAM ロール付与
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  # user_data を外部ファイル（user_data.sh）から読み込む
  # ---------------------------------------------------------
  user_data = base64encode(
    templatefile("${path.module}/../app/user_data.sh", {
      DB_HOST     = aws_db_instance.database.address
      DB_PASSWORD = var.db_password

      APP_PY     = file("${path.module}/../app/app.py")
      INDEX_HTML = file("${path.module}/../app/templates/index.html")
    })
  )
}
