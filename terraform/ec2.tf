resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  # RDS が先に必要なので依存関係を明示
  depends_on = [aws_db_instance.mysql]

  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  # user_data は Terraform が展開しないように <<EOF（クォートなし）
  user_data = base64encode(<<EOF
#!/bin/bash
set -eux

# ---------------------------------------------------------
# OS アップデート
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# Python / pip / MySQL / nginx
# ---------------------------------------------------------
dnf install -y python3 python3-pip mariadb105 nginx

# ---------------------------------------------------------
# RDS 接続情報（環境変数）
# ---------------------------------------------------------
echo "DB_HOST=${aws_db_instance.mysql.address}" >> /etc/environment
echo "DB_USER=admin" >> /etc/environment
echo "DB_PASSWORD=${var.db_password}" >> /etc/environment
echo "DB_NAME=employees" >> /etc/environment
source /etc/environment

# ---------------------------------------------------------
# RDS 起動待ち（3306 が開くまで待機）
# ---------------------------------------------------------
echo "Waiting for RDS..."
until nc -z -w5 "$DB_HOST" 3306; do
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

# app.py を Base64 から復元
echo "aW1wb3J0IG9zDQppbXBvcnQgbXlzcWwuY29ubmVjdG9yDQpmcm9tIGZsYXNrIGltcG9ydCBGbGFz
aywgcmVxdWVzdA0KDQphcHAgPSBGbGFzayhfX25hbWVfXykNCg0KZGJfY29uZmlnID0gew0KICAg
ICJob3N0Ijogb3MuZ2V0ZW52KCJEQl9IT1NUIiksDQogICAgInVzZXIiOiBvcy5nZXRlbnYoIkRC
X1VTRVIiKSwNCiAgICAicGFzc3dvcmQiOiBvcy5nZXRlbnYoIkRCX1BBU1NXT1JEIiksDQogICAg
ImRhdGFiYXNlIjogb3MuZ2V0ZW52KCJEQl9OQU1FIikNCn0NCg0KQGFwcC5yb3V0ZSgiLyIpDQpk
ZWYgaW5kZXgoKToNCiAgICBuYW1lID0gcmVxdWVzdC5hcmdzLmdldCgibmFtZSIsICIiKQ0KICAg
IGxpa2VfdmFsdWUgPSAiJSIgKyBuYW1lICsgIiUiDQogICAgY29ubiA9IG15c3FsLmNvbm5lY3Rv
ci5jb25uZWN0KCoqZGJfY29uZmlnKQ0KICAgIGN1ciA9IGNvbm4uY3Vyc29yKCkNCiAgICBjdXIu
ZXhlY3V0ZSgNCiAgICAgICAgIlNFTEVDVCBpZCwgbmFtZSwgZGVwYXJ0bWVudCBGUk9NIGVtcGxv
eWVlcyBXSEVSRSBuYW1lIExJS0UgJXMiLA0KICAgICAgICAobGlrZV92YWx1ZSwpDQogICAgKQ0K
ICAgIHJvd3MgPSBjdXIuZmV0Y2hhbGwoKQ0KICAgIGN1ci5jbG9zZSgpDQogICAgY29ubi5jbG9z
ZSgpDQogICAgcmV0dXJuIHN0cihyb3dzKQ0KDQppZiBfX25hbWVfXyA9PSAiX19tYWluX18iOg0K
ICAgIGFwcC5ydW4oaG9zdD0iMC4wLjAuMCIsIHBvcnQ9NTAwMCkNCg==
" | base64 -d > /opt/flask_app/app.py

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
