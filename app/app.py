import os
import math
import mysql.connector
from flask import Flask, request, render_template

app = Flask(__name__)

PAGE_SIZE = 20  # 1ページあたりの件数

db_config = {
    "host": os.getenv("DB_HOST"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD"),
    "database": os.getenv("DB_NAME")
}


def has_fulltext_index(conn):
    # employees テーブルに name の FULLTEXT があるか確認
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
    name = request.args.get("name", "").strip()
    page = request.args.get("page", "1")
    try:
        page = max(1, int(page))
    except ValueError:
        page = 1

    offset = (page - 1) * PAGE_SIZE

    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()

    # 検索あり/なしで SQL を切り替え（全文検索が使えるなら MATCH を優先）
    if name:
        if has_fulltext_index(conn):
            # FULLTEXT がある場合（自然言語検索 or boolean）
            # boolean モードで部分一致に近い検索も可能（例: +keyword*）
            ft_query = "SELECT id, name, department FROM employees WHERE MATCH(name) AGAINST(%s IN BOOLEAN MODE) LIMIT %s OFFSET %s"
            ft_count_q = "SELECT COUNT(*) FROM employees WHERE MATCH(name) AGAINST(%s IN BOOLEAN MODE)"
            # boolean モード用の検索語（末尾ワイルドカード）
            ft_search = f"{name}*"
            cur.execute(ft_count_q, (ft_search,))
            total = cur.fetchone()[0]
            cur.execute(ft_query, (ft_search, PAGE_SIZE, offset))
            employees = cur.fetchall()
        else:
            # FULLTEXT が無い場合は LIKE（フォールバック）
            like_value = "%" + name + "%"
            cur.execute(
                "SELECT COUNT(*) FROM employees WHERE name LIKE %s", (like_value,))
            total = cur.fetchone()[0]
            cur.execute(
                "SELECT id, name, department FROM employees WHERE name LIKE %s LIMIT %s OFFSET %s",
                (like_value, PAGE_SIZE, offset)
            )
            employees = cur.fetchall()
    else:
        # 検索なし：全件取得（ページネーション）
        cur.execute("SELECT COUNT(*) FROM employees")
        total = cur.fetchone()[0]
        cur.execute(
            "SELECT id, name, department FROM employees ORDER BY id LIMIT %s OFFSET %s",
            (PAGE_SIZE, offset)
        )
        employees = cur.fetchall()

    cur.close()
    conn.close()

    total_pages = max(1, math.ceil(total / PAGE_SIZE))

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
