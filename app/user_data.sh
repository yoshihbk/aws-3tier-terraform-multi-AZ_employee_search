#!/bin/bash
set -ux

# ---------------------------------------------------------
# OS アップデート
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# Python / pip / MySQL クライアント / nginx
# ---------------------------------------------------------
dnf install -y python3 python3-pip mariadb105 nginx

# ---------------------------------------------------------
# RDS 接続情報（環境変数）
# ---------------------------------------------------------
echo "DB_HOST=${DB_HOST}" >> /etc/environment
echo "DB_USER=admin" >> /etc/environment
echo "DB_PASSWORD=${DB_PASSWORD}" >> /etc/environment
echo "DB_NAME=employees" >> /etc/environment
source /etc/environment

# ---------------------------------------------------------
# RDS 起動待ち
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
# Flask アプリ配置
# ---------------------------------------------------------
mkdir -p /opt/flask_app
mkdir -p /opt/flask_app/templates

# app.py 配置
cat << 'EOF' > /opt/flask_app/app.py
${APP_PY}
EOF

# index.html 配置
cat << 'EOF' > /opt/flask_app/templates/index.html
${INDEX_HTML}
EOF

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
EnvironmentFile=/etc/environment
ExecStart=/usr/bin/python3 /opt/flask_app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
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
