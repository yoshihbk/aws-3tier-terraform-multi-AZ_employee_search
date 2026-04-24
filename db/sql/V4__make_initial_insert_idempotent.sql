-- ============================================
-- V4: 初期データの冪等 INSERT（email 付き）
-- UNIQUE(email) に基づき、重複行は無視される
-- ============================================

INSERT IGNORE INTO employees (name, department, email) VALUES
('山田太郎', '営業', 'taro@example.com'),
('佐藤花子', '総務', 'hanako@example.com'),
('鈴木一郎', 'IT', 'ichiro@example.com'),
('田中健', '人事', 'ken@example.com'),
('高橋優', '経理', 'yu@example.com');
