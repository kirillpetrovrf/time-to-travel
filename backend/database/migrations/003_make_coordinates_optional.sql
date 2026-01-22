-- Миграция 003: Сделать координаты и расчёты опциональными
-- Причина: Flutter приложение отправляет только адреса и finalPrice
-- Координаты и детальные расчёты будут вычисляться позже (диспетчером или автоматически)

ALTER TABLE orders 
    ALTER COLUMN from_lat DROP NOT NULL,
    ALTER COLUMN from_lon DROP NOT NULL,
    ALTER COLUMN to_lat DROP NOT NULL,
    ALTER COLUMN to_lon DROP NOT NULL,
    ALTER COLUMN distance_km DROP NOT NULL,
    ALTER COLUMN raw_price DROP NOT NULL,
    ALTER COLUMN base_cost DROP NOT NULL,
    ALTER COLUMN cost_per_km DROP NOT NULL;

-- Комментарии для документации
COMMENT ON COLUMN orders.from_lat IS 'Широта начальной точки (опционально - может быть null при создании)';
COMMENT ON COLUMN orders.from_lon IS 'Долгота начальной точки (опционально - может быть null при создании)';
COMMENT ON COLUMN orders.to_lat IS 'Широта конечной точки (опционально - может быть null при создании)';
COMMENT ON COLUMN orders.to_lon IS 'Долгота конечной точки (опционально - может быть null при создании)';
COMMENT ON COLUMN orders.distance_km IS 'Расстояние в км (опционально - вычисляется позже)';
COMMENT ON COLUMN orders.raw_price IS 'Базовая цена без наценок (опционально - вычисляется позже)';
COMMENT ON COLUMN orders.base_cost IS 'Базовая стоимость (опционально - вычисляется позже)';
COMMENT ON COLUMN orders.cost_per_km IS 'Стоимость за км (опционально - вычисляется позже)';
