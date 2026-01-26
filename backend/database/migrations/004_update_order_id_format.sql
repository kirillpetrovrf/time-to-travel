-- Миграция: Обновление формата order_id
-- Старый формат: ORDER-2026-01-391
-- Новый формат: 2026-01-26-391-G (год-месяц-день-номер-тип)
-- 
-- Типы поездок:
-- G - Group (Групповая)
-- I - Individual (Индивидуальная)  
-- S - Svobodnaya/Custom (Свободная)
--
-- Дата: 26 января 2026

-- ВНИМАНИЕ: Выполнять после бэкапа БД!

-- Обновление существующих заказов
UPDATE orders 
SET order_id = CONCAT(
  TO_CHAR(created_at, 'YYYY-MM-DD'), 
  '-',
  -- Берём последние 3 цифры из старого order_id или используем случайное число
  LPAD(
    COALESCE(
      NULLIF(regexp_replace(order_id, '^ORDER-\d{4}-\d{2}-', ''), ''),
      LPAD(CAST(EXTRACT(MILLISECONDS FROM created_at) % 1000 AS TEXT), 3, '0')
    ),
    3, 
    '0'
  ),
  '-',
  -- Добавляем суффикс типа поездки
  CASE 
    WHEN trip_type = 'group' THEN 'G'
    WHEN trip_type = 'individual' THEN 'I'
    WHEN trip_type = 'customRoute' THEN 'S'
    ELSE 'S' -- По умолчанию свободная
  END
)
WHERE order_id LIKE 'ORDER-%';

-- Проверка результата
SELECT 
  order_id,
  trip_type,
  created_at,
  status
FROM orders
ORDER BY created_at DESC
LIMIT 10;

-- Вывод статистики
SELECT 
  COUNT(*) as total_orders,
  COUNT(CASE WHEN order_id LIKE 'ORDER-%' THEN 1 END) as old_format,
  COUNT(CASE WHEN order_id ~ '^\d{4}-\d{2}-\d{2}-\d{3}-[GIS]$' THEN 1 END) as new_format
FROM orders;
