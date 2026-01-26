-- Migration: 002_make_coordinates_nullable.sql
-- Description: Allow NULL coordinates for orders (geocoding will be added later)
-- Author: AI Assistant
-- Date: 2026-01-26

BEGIN;

-- Make coordinates nullable (client may not provide them initially)
ALTER TABLE orders ALTER COLUMN from_lat DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN from_lon DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN to_lat DROP NOT NULL;
ALTER TABLE orders ALTER COLUMN to_lon DROP NOT NULL;

-- Add helpful comments for future developers
COMMENT ON COLUMN orders.from_lat IS 'Latitude of departure point. NULL if not provided by client (will be geocoded from address)';
COMMENT ON COLUMN orders.from_lon IS 'Longitude of departure point. NULL if not provided by client (will be geocoded from address)';
COMMENT ON COLUMN orders.to_lat IS 'Latitude of destination point. NULL if not provided by client (will be geocoded from address)';
COMMENT ON COLUMN orders.to_lon IS 'Longitude of destination point. NULL if not provided by client (will be geocoded from address)';

COMMIT;

-- Verification query
-- SELECT order_id, from_address, from_lat, from_lon FROM orders LIMIT 5;
