-- Добавление поля role в таблицу users
-- Дата: 22 января 2026

-- Добавляем колонку role
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'client';

-- Обновляем существующих пользователей
UPDATE users SET role = 'admin' WHERE email = 'admin@titotr.ru';
UPDATE users SET role = 'driver' WHERE email = 'driver@titotr.ru';
UPDATE users SET role = 'client' WHERE role IS NULL OR role = '';

-- Индекс для роли
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
