-- Миграция 004: Добавить trip_type и direction для правильной работы типов поездок
-- Причина: В SQLite эти данные сохранялись, но в PostgreSQL они отсутствуют
-- Типы поездок: 'group' (групповая), 'individual' (индивидуальный трансфер), 'customRoute' (свободный маршрут)
-- Направления: 'donetskToRostov', 'rostovToDonetsk'

-- Добавляем колонку trip_type
ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS trip_type VARCHAR(50);

-- Добавляем колонку direction
ALTER TABLE orders 
    ADD COLUMN IF NOT EXISTS direction VARCHAR(50);

-- Комментарии для документации
COMMENT ON COLUMN orders.trip_type IS 'Тип поездки: group (групповая), individual (индивидуальный трансфер), customRoute (свободный маршрут/такси)';
COMMENT ON COLUMN orders.direction IS 'Направление: donetskToRostov или rostovToDonetsk (только для group и individual)';

-- Создаем индексы для быстрого поиска по типу и направлению
CREATE INDEX IF NOT EXISTS idx_orders_trip_type ON orders(trip_type);
CREATE INDEX IF NOT EXISTS idx_orders_direction ON orders(direction);

-- Для существующих записей устанавливаем customRoute по умолчанию
UPDATE orders
SET trip_type = 'customRoute'
WHERE trip_type IS NULL;
