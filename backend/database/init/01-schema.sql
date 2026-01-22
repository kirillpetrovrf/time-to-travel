-- Time to Travel PostgreSQL Schema
-- Миграция со SQLite на PostgreSQL
-- Создано: 21 января 2026

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm"; -- для полнотекстового поиска

-- ============================================
-- ТАБЛИЦА: users (Пользователи)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    is_verified BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================
-- ТАБЛИЦА: refresh_tokens (JWT Refresh Tokens)
-- ============================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для refresh_tokens
CREATE INDEX idx_refresh_tokens_user_id ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens(expires_at);

-- ============================================
-- ТАБЛИЦА: route_groups (Группы маршрутов)
-- ============================================
CREATE TABLE route_groups (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для route_groups
CREATE INDEX idx_route_groups_is_active ON route_groups(is_active);

-- ============================================
-- ТАБЛИЦА: predefined_routes (Предопределенные маршруты)
-- Мигрировано из SQLite таблицы: predefined_routes
-- ============================================
CREATE TABLE predefined_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_city VARCHAR(255) NOT NULL,
    to_city VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    group_id UUID REFERENCES route_groups(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для predefined_routes
CREATE INDEX idx_predefined_routes_cities ON predefined_routes(from_city, to_city);
CREATE INDEX idx_predefined_routes_group_id ON predefined_routes(group_id);
CREATE INDEX idx_predefined_routes_is_active ON predefined_routes(is_active);

-- ============================================
-- ТАБЛИЦА: orders (Заказы/Бронирования)
-- Мигрировано из SQLite таблицы: orders
-- ============================================
CREATE TABLE orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id VARCHAR(255) UNIQUE NOT NULL, -- Внешний ID для клиента
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    
    -- Координаты
    from_lat DECIMAL(10, 7) NOT NULL,
    from_lon DECIMAL(10, 7) NOT NULL,
    to_lat DECIMAL(10, 7) NOT NULL,
    to_lon DECIMAL(10, 7) NOT NULL,
    
    -- Адреса
    from_address TEXT NOT NULL,
    to_address TEXT NOT NULL,
    
    -- Расстояние и цены
    distance_km DECIMAL(10, 2) NOT NULL,
    raw_price DECIMAL(10, 2) NOT NULL,
    final_price DECIMAL(10, 2) NOT NULL,
    base_cost DECIMAL(10, 2) NOT NULL,
    cost_per_km DECIMAL(10, 2) NOT NULL,
    
    -- Статус заказа
    status VARCHAR(50) NOT NULL DEFAULT 'pending',
    -- pending, confirmed, in_progress, completed, cancelled
    
    -- Информация о клиенте
    client_name VARCHAR(255),
    client_phone VARCHAR(20),
    
    -- Дата и время поездки
    departure_date DATE,
    departure_time TIME,
    
    -- Пассажиры (JSON массив)
    passengers JSONB,
    -- Пример: [{"name": "Иван", "age": 30}, {"name": "Мария", "age": 25}]
    
    -- Багаж (JSON массив)
    baggage JSONB,
    -- Пример: [{"type": "suitcase", "size": "large", "count": 2}]
    
    -- Животные (JSON массив)
    pets JSONB,
    -- Пример: [{"type": "dog", "name": "Рекс", "weight": 15}]
    
    -- Заметки
    notes TEXT,
    
    -- Класс автомобиля
    vehicle_class VARCHAR(50),
    -- economy, comfort, business, minivan
    
    -- Метаданные
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для orders
CREATE INDEX idx_orders_order_id ON orders(order_id);
CREATE INDEX idx_orders_user_id ON orders(user_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_departure_date ON orders(departure_date);
CREATE INDEX idx_orders_created_at ON orders(created_at);
CREATE INDEX idx_orders_client_phone ON orders(client_phone);

-- GIN индекс для JSONB полей (для быстрого поиска в JSON)
CREATE INDEX idx_orders_passengers ON orders USING GIN (passengers);
CREATE INDEX idx_orders_baggage ON orders USING GIN (baggage);
CREATE INDEX idx_orders_pets ON orders USING GIN (pets);

-- ============================================
-- ТАБЛИЦА: payments (Платежи)
-- ============================================
CREATE TABLE payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    amount DECIMAL(10, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'RUB',
    payment_method VARCHAR(50),
    -- card, cash, sbp, yookassa, tinkoff
    payment_provider VARCHAR(50),
    transaction_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'pending',
    -- pending, processing, completed, failed, refunded
    paid_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Индексы для payments
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_payments_status ON payments(status);
CREATE INDEX idx_payments_transaction_id ON payments(transaction_id);

-- ============================================
-- ТРИГГЕРЫ для автоматического обновления updated_at
-- ============================================

-- Функция для обновления updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггер для users
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Триггер для route_groups
CREATE TRIGGER update_route_groups_updated_at 
    BEFORE UPDATE ON route_groups
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Триггер для predefined_routes
CREATE TRIGGER update_predefined_routes_updated_at 
    BEFORE UPDATE ON predefined_routes
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Триггер для orders
CREATE TRIGGER update_orders_updated_at 
    BEFORE UPDATE ON orders
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- КОММЕНТАРИИ К ТАБЛИЦАМ
-- ============================================

COMMENT ON TABLE users IS 'Пользователи приложения';
COMMENT ON TABLE refresh_tokens IS 'JWT Refresh токены для аутентификации';
COMMENT ON TABLE route_groups IS 'Группы маршрутов для организации';
COMMENT ON TABLE predefined_routes IS 'Предопределенные маршруты с ценами';
COMMENT ON TABLE orders IS 'Заказы такси / бронирования поездок';
COMMENT ON TABLE payments IS 'Платежи за заказы';

-- ============================================
-- СТАТИСТИКА И ПРОВЕРКА
-- ============================================

-- Проверка созданных таблиц
DO $$
BEGIN
    RAISE NOTICE '✅ База данных Time to Travel успешно инициализирована!';
    RAISE NOTICE '📊 Созданные таблицы:';
    RAISE NOTICE '  - users (пользователи)';
    RAISE NOTICE '  - refresh_tokens (JWT токены)';
    RAISE NOTICE '  - route_groups (группы маршрутов)';
    RAISE NOTICE '  - predefined_routes (предопределенные маршруты)';
    RAISE NOTICE '  - orders (заказы)';
    RAISE NOTICE '  - payments (платежи)';
END $$;
