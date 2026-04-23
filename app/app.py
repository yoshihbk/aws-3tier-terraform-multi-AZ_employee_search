import os
import mysql.connector
from flask import Flask, request, render_template

# ---------------------------------------------------------
# Flask アプリケーション
# ---------------------------------------------------------
app = Flask(__name__)

# ---------------------------------------------------------
# RDS 接続情報（環境変数から取得）
# ---------------------------------------------------------
db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}

# ---------------------------------------------------------
# ルートページ（社員検索）
# ---------------------------------------------------------


@app.route("/")
def index():
    # GET パラメータ name を取得
    name = request.args.get("name", "")
    like_value = "%" + name + "%"

    # DB 接続
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    cur.execute(
        "SELECT id, name, department FROM employees WHERE name LIKE %s",
        (like_value,)
    )
    rows = cur.fetchall()
    cur.close()
    conn.close()

    # -----------------------------------------------------
    # rows が空ならメッセージを渡す
    # -----------------------------------------------------
    message = None
    if len(rows) == 0:
        message = "該当社員はおりません"

    # HTML に employees と message を渡す
    return render_template("index.html", employees=rows, keyword=name, message=message)


# ---------------------------------------------------------
# ローカル実行用
# ---------------------------------------------------------
if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
