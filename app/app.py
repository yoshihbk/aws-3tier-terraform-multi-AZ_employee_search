import os
import math
import mysql.connector
from flask import Flask, request, render_template

app = Flask(__name__)

# 1ページあたりの件数
PAGE_SIZE = 20

# DB接続情報（環境変数から取得）
db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}


def has_fulltext_index(conn):
    """
    employees.name に FULLTEXT INDEX があるか確認する関数
    """
    cur = conn.cursor()
    cur.execute("""
        SELECT COUNT(*) 
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = %s
          AND TABLE_NAME = 'employees'
          AND INDEX_TYPE = 'FULLTEXT'
          AND COLUMN_NAME = 'name'
    """, (db_config["database"],))
    exists = cur.fetchone()[0] > 0
    cur.close()
    return exists


@app.route("/", methods=["GET"])
def index():
    """
    社員一覧ページ
    - 検索あり：検索結果のみ表示
    - 検索なし：全件表示
    ※ 二重表示を防ぐため、employees は必ず1回だけ取得して1回だけ描画
    """

    # 検索ワード
    name = request.args.get("name", "").strip()

    # ページ番号
    page = request.args.get("page", "1")
    try:
        page = max(1, int(page))
    except ValueError:
        page = 1

    offset = (page - 1) * PAGE_SIZE

    # DB接続
    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()

    # -----------------------------
    # ① 検索ありの場合
    # -----------------------------
    if name:
        if has_fulltext_index(conn):
            # FULLTEXT検索（booleanモード）
            ft_search = f"{name}*"

            # 件数取得
            cur.execute(
                "SELECT COUNT(*) FROM employees WHERE MATCH(name) AGAINST(%s IN BOOLEAN MODE)",
                (ft_search,)
            )
            total = cur.fetchone()[0]

            # データ取得（email を必ず含める）
            cur.execute(
                "SELECT id, name, department, email FROM employees "
                "WHERE MATCH(name) AGAINST(%s IN BOOLEAN MODE) "
                "LIMIT %s OFFSET %s",
                (ft_search, PAGE_SIZE, offset)
            )
            employees = cur.fetchall()

        else:
            # LIKE検索
            like_value = "%" + name + "%"

            cur.execute(
                "SELECT COUNT(*) FROM employees WHERE name LIKE %s",
                (like_value,)
            )
            total = cur.fetchone()[0]

            cur.execute(
                "SELECT id, name, department, email FROM employees "
                "WHERE name LIKE %s "
                "LIMIT %s OFFSET %s",
                (like_value, PAGE_SIZE, offset)
            )
            employees = cur.fetchall()

    # -----------------------------
    # ② 検索なし（全件表示）
    # -----------------------------
    else:
        cur.execute("SELECT COUNT(*) FROM employees")
        total = cur.fetchone()[0]

        cur.execute(
            "SELECT id, name, department, email FROM employees "
            "ORDER BY id LIMIT %s OFFSET %s",
            (PAGE_SIZE, offset)
        )
        employees = cur.fetchall()

    # DBクローズ
    cur.close()
    conn.close()

    # 総ページ数
    total_pages = max(1, math.ceil(total / PAGE_SIZE))

    # index.html に employees を1回だけ渡す
    return render_template(
        "index.html",
        employees=employees,
        count=total,
        name=name,
        page=page,
        total_pages=total_pages,
        page_size=PAGE_SIZE
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
