cat << 'EOF' > V1__create_tables.sql
-- ============================================
-- V1: employees テーブルの作成
-- Flyway による最初のマイグレーション。
-- テーブル構造（スキーマ）を定義する。
-- ============================================

CREATE TABLE employees (
  id INT AUTO_INCREMENT PRIMARY KEY,   -- 主キー（自動採番）
  name VARCHAR(255),                   -- 社員名
  department VARCHAR(255)              -- 部署名
);
EOF
