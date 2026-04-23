#!/bin/bash

# ---------------------------------------------------------
# Flask アプリ配置用ディレクトリを作成
# （/opt/flask_app 配下にアプリ本体とテンプレートを配置する）
# ---------------------------------------------------------
mkdir -p /opt/flask_app
mkdir -p /opt/flask_app/templates

# ---------------------------------------------------------
# app.py を EC2 内に配置
# Terraform の file() でローカルの app/app.py を読み込み
# cat << EOF で EC2 側にファイルとして書き出す
# ---------------------------------------------------------
cat << 'EOF' > /opt/flask_app/app.py
${file("${path.module}/../app/app.py")}
EOF

# ---------------------------------------------------------
# index.html を EC2 内に配置
# Flask のテンプレートディレクトリ（templates/）に配置する
# ---------------------------------------------------------
cat << 'EOF' > /opt/flask_app/templates/index.html
${file("${path.module}/../app/templates/index.html")}
EOF

# ---------------------------------------------------------
# Flask systemd サービスを再起動
# （app.py と index.html の更新を反映させる）
# ---------------------------------------------------------
systemctl restart flask
