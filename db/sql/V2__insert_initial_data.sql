cat << 'EOF' > V2__insert_initial_data.sql
-- ============================================
-- V2: 初期データ投入
-- V1 のテーブル作成後に実行される。
-- 開発・検証用のサンプルデータを登録する。
-- Flyway により一度しか実行されない。
-- ============================================

-- ============================================
-- V2: 初期データ投入（email 対応・冪等）
-- ============================================

INSERT IGNORE INTO employees (name, department, email) VALUES
('山田太郎', '営業', 'taro@example.com'),
('佐藤花子', '総務', 'hanako@example.com'),
('鈴木一郎', 'IT', 'ichiro@example.com'),
('田中健', '人事', 'ken@example.com'),
('高橋優', '経理', 'yu@example.com');
EOF
