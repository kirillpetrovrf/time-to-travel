-- Migration: 003_optimize_indexes.sql
-- Description: Add missing indexes for frequent queries
-- Author: AI Assistant
-- Date: 2026-01-26

BEGIN;

-- Index for dispatcher queries (status + created_at)
-- Used when dispatcher filters orders by status and sorts by date
CREATE INDEX IF NOT EXISTS idx_orders_status_created_at 
ON orders(status, created_at DESC);

-- Index for user's order history
-- Used when client views their own orders
CREATE INDEX IF NOT EXISTS idx_orders_user_created_at 
ON orders(user_id, created_at DESC) 
WHERE user_id IS NOT NULL;

-- Index for phone-based lookup (guest orders without user_id)
CREATE INDEX IF NOT EXISTS idx_orders_client_phone 
ON orders(client_phone) 
WHERE client_phone IS NOT NULL;

-- Composite index for trip filtering
-- Used when filtering by trip type and direction
CREATE INDEX IF NOT EXISTS idx_orders_trip_direction 
ON orders(trip_type, direction) 
WHERE trip_type IS NOT NULL;

-- GIN index for JSONB fields (passengers, baggage, pets)
-- Used when searching within JSON data
CREATE INDEX IF NOT EXISTS idx_orders_passengers_gin 
ON orders USING GIN (passengers);

CREATE INDEX IF NOT EXISTS idx_orders_baggage_gin 
ON orders USING GIN (baggage);

CREATE INDEX IF NOT EXISTS idx_orders_pets_gin 
ON orders USING GIN (pets);

COMMIT;

-- Verify indexes
-- SELECT schemaname, tablename, indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'orders'
-- ORDER BY indexname;
