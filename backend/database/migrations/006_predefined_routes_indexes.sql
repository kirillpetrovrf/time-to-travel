-- migrations/006_predefined_routes_indexes.sql
-- Оптимизация индексов для поиска маршрутов

BEGIN;

-- Индекс для поиска по городу отправления (полнотекстовый)
CREATE INDEX IF NOT EXISTS idx_predefined_routes_from_city_lower 
    ON predefined_routes(LOWER(from_city));

-- Индекс для поиска по городу назначения (полнотекстовый)
CREATE INDEX IF NOT EXISTS idx_predefined_routes_to_city_lower 
    ON predefined_routes(LOWER(to_city));

-- Композитный индекс для поиска направления
CREATE INDEX IF NOT EXISTS idx_predefined_routes_direction 
    ON predefined_routes(from_city, to_city) WHERE is_active = true;

-- Индекс для группировки маршрутов
CREATE INDEX IF NOT EXISTS idx_predefined_routes_group 
    ON predefined_routes(group_id) WHERE group_id IS NOT NULL;

COMMIT;
