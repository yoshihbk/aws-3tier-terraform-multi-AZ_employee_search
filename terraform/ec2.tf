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

  # ---------------------------------------------------------
  # user_data（Amazon Linux 2023 で確実に動く完全版）
  # ---------------------------------------------------------
  user_data = base64encode(<<EOF
#!/bin/bash
# -e を外すことで、途中のコマンド失敗で user_data 全体が止まるのを防ぐ
set -ux

# ---------------------------------------------------------
# OS アップデート
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# Python / pip / MySQL クライアント / nginx
# Amazon Linux 2023 では mysql パッケージが無く、
# mariadb105 が MySQL 互換クライアントとして提供される
# ---------------------------------------------------------
dnf install -y python3 python3-pip mariadb105 nginx

# ---------------------------------------------------------
# RDS 接続情報（環境変数）
# ---------------------------------------------------------
echo "DB_HOST=${aws_db_instance.database.address}" >> /etc/environment
echo "DB_USER=admin" >> /etc/environment
echo "DB_PASSWORD=${var.db_password}" >> /etc/environment
echo "DB_NAME=employees" >> /etc/environment
source /etc/environment

# ---------------------------------------------------------
# RDS 起動待ち
# mysqladmin が無い環境があるため mysql -e で待つ
# ---------------------------------------------------------
echo "Waiting for RDS..."
until mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
  echo "RDS not ready..."
  sleep 5
done
echo "RDS is ready!"

# ---------------------------------------------------------
# DB / TABLE / 初期データ作成
# ---------------------------------------------------------
mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" <<SQL
CREATE DATABASE IF NOT EXISTS employees;
USE employees;

CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100),
  department VARCHAR(100)
);

INSERT INTO employees (name, department) VALUES
('山田太郎','営業'),
('佐藤花子','総務'),
('鈴木一郎','IT'),
('田中健','人事'),
('高橋優','経理');
SQL

# ---------------------------------------------------------
# Flask アプリ配置（Base64 から復元）
# ---------------------------------------------------------
mkdir -p /opt/flask_app

# app/app.b64 を Terraform 側に置いておけばこれで展開できる
echo "${file("app/app.b64")}" | base64 -d > /opt/flask_app/app.py

# ---------------------------------------------------------
# Flask / MySQL Connector インストール
# ---------------------------------------------------------
pip3 install flask mysql-connector-python

# ---------------------------------------------------------
# systemd Flask サービス
# ---------------------------------------------------------
cat > /etc/systemd/system/flask.service <<SERVICE
[Unit]
Description=Flask App
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/flask_app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now flask

# ---------------------------------------------------------
# nginx（リバースプロキシ）
# ---------------------------------------------------------
cat > /etc/nginx/conf.d/flask.conf <<NGINX
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:5000;
    }
}
NGINX

systemctl enable --now nginx

EOF
  )
}
