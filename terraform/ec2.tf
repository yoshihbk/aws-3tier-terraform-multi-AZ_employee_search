# Launch Template for EC2 (Web/App)
resource "aws_launch_template" "web_lt" {
  name = "web-launch-template"

  image_id      = data.aws_ssm_parameter.al2023.value
  instance_type = "t2.micro"

  vpc_security_group_ids = [
    aws_security_group.ec2_sg.id
  ]

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_ssm_profile.name
  }

  user_data = base64encode(<<EOF
#!/bin/bash
set -eux

# ---------------------------------------------------------
# 基本アップデート
# ---------------------------------------------------------
dnf update -y

# ---------------------------------------------------------
# Python / pip
# ---------------------------------------------------------
dnf install -y python3 python3-pip

# ---------------------------------------------------------
# RDS 接続情報（環境変数）
# ---------------------------------------------------------
echo "DB_HOST=${aws_db_instance.mysql.address}" >> /etc/environment
echo "DB_USER=admin" >> /etc/environment
echo "DB_PASSWORD=${var.db_password}" >> /etc/environment
echo "DB_NAME=employees" >> /etc/environment

# ---------------------------------------------------------
# Flask アプリ配置
# ---------------------------------------------------------
mkdir -p /opt/flask_app

cat << 'APP' > /opt/flask_app/app.py
import os
import mysql.connector
from flask import Flask, request

app = Flask(__name__)

db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

@app.route("/")
def index():
    name = request.args.get("name", "")
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    cur.execute("SELECT id, name, department FROM employees WHERE name LIKE %s", (f"%$${name}%",))
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return str(rows)

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
APP

# ---------------------------------------------------------
# requirements.txt
# ---------------------------------------------------------
cat << 'REQ' > /opt/flask_app/requirements.txt
flask
mysql-connector-python
REQ

pip3 install -r /opt/flask_app/requirements.txt

# ---------------------------------------------------------
# systemd（Flask）
# ---------------------------------------------------------
cat << 'SERVICE' > /etc/systemd/system/flask.service
[Unit]
Description=Flask App
After=network.target

[Service]
User=root
WorkingDirectory=/opt/flask_app
ExecStart=/usr/bin/python3 /opt/flask_app/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl enable --now flask

# ---------------------------------------------------------
# nginx（リバースプロキシ）
# ---------------------------------------------------------
dnf install -y nginx

cat << 'NGINX' > /etc/nginx/conf.d/flask.conf
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
