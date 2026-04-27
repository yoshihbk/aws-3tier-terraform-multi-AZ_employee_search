-- ============================================
-- V1: employees テーブルの作成
-- ・name + department + email の組み合わせを UNIQUE にする
--   → 重複登録を防ぐため
-- ============================================

CREATE TABLE IF NOT EXISTS employees (
  id INT AUTO_INCREMENT PRIMARY KEY,          -- 主キー（自動採番）
  name VARCHAR(255),                          -- 社員名
  department VARCHAR(255),                    -- 部署名
  email VARCHAR(255),                         -- メールアドレス
  UNIQUE KEY uniq_employee (name, department, email)  -- 重複防止の一意制約
);
