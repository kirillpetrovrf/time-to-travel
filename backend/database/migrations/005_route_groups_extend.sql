-- migrations/005_route_groups_extend.sql
-- Расширение таблицы route_groups для CRM системы маршрутов

BEGIN;

-- Добавляем поле base_price для базовой цены группы
ALTER TABLE route_groups 
    ADD COLUMN IF NOT EXISTS base_price DECIMAL(10, 2) DEFAULT 0;

-- Комментарии для документации
COMMENT ON COLUMN route_groups.base_price IS 'Базовая цена для всех маршрутов группы';

-- Индекс для быстрого поиска активных групп
CREATE INDEX IF NOT EXISTS idx_route_groups_active 
    ON route_groups(is_active) WHERE is_active = true;

COMMIT;
