-- ============================================
-- V3: email カラムの追加 + UNIQUE 制約の付与
-- 目的：
--   ・社員を email で一意に識別できるようにする
--   ・name + department ではなく email を UNIQUE にする
--   ・後から追加しても Flyway により安全に適用される
-- ============================================

ALTER TABLE employees
ADD COLUMN email VARCHAR(255) NOT NULL,
ADD CONSTRAINT unique_employee_email UNIQUE (email);
