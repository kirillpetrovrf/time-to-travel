-- Таблица пользователей (пассажиры + диспетчер)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  telegram_id BIGINT UNIQUE,
  phone VARCHAR(20) UNIQUE,
  first_name VARCHAR(100),
  last_name VARCHAR(100),
  username VARCHAR(100),
  role VARCHAR(20) DEFAULT 'passenger',
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  last_login TIMESTAMP
);

-- Таблица сессий для токенов
CREATE TABLE IF NOT EXISTS user_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  refresh_token TEXT UNIQUE NOT NULL,
  device_info TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  expires_at TIMESTAMP,
  last_used TIMESTAMP DEFAULT NOW()
);

-- Индексы для быстрого поиска
CREATE INDEX IF NOT EXISTS idx_users_telegram ON users(telegram_id);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_sessions_token ON user_sessions(refresh_token);
CREATE INDEX IF NOT EXISTS idx_sessions_user ON user_sessions(user_id);

-- Создаём ОДНОГО диспетчера с фиксированным доступом
INSERT INTO users (telegram_id, phone, first_name, role, is_active)
VALUES (999999999, '+79999999999', 'Dispatcher', 'dispatcher', true)
ON CONFLICT (telegram_id) DO NOTHING;

-- Даём права на новые таблицы
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO timetotravel;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO timetotravel;

SELECT 'Таблицы созданы!' AS status;
SELECT id, telegram_id, phone, first_name, role FROM users WHERE role = 'dispatcher';
