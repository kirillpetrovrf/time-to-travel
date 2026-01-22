-- Обновление хешей паролей тестовых пользователей
-- Дата: 22 января 2026
-- Пароль для всех: Test123!

UPDATE users 
SET password_hash = '$2a$10$0w7VRSHuJ8xrFx.zpezLquY1pRPXLVqZy1Js89u8.cfl5eJGJRBkW'
WHERE email IN ('admin@titotr.ru', 'driver@titotr.ru', 'client@example.com');
