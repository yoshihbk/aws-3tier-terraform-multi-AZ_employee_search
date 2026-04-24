import os
import mysql.connector
from flask import Flask, request, render_template

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
    like_value = "%" + name + "%"

    conn = mysql.connector.connect(**db_config)
    cur = conn.cursor()
    cur.execute(
        "SELECT id, name, department FROM employees WHERE name LIKE %s",
        (like_value,)
    )
    employees = cur.fetchall()
    cur.close()
    conn.close()

    count = len(employees)

    return render_template(
        "index.html",
        employees=employees,
        count=count,
        name=name
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
