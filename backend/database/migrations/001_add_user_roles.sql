-- Migration: 001_add_user_roles.sql
-- Description: Add role column to users table for RBAC (Role-Based Access Control)
-- Author: AI Assistant
-- Date: 2026-01-26

BEGIN;

-- Add role column with default value 'client'
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS role VARCHAR(20) DEFAULT 'client' NOT NULL;

-- Add constraint to validate roles
ALTER TABLE users
DROP CONSTRAINT IF EXISTS users_role_check;

ALTER TABLE users
ADD CONSTRAINT users_role_check 
CHECK (role IN ('client', 'dispatcher', 'admin'));

-- Create index for faster role-based queries
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Update existing users with proper roles
UPDATE users 
SET role = 'admin' 
WHERE email = 'admin@titotr.ru';

UPDATE users 
SET role = 'dispatcher' 
WHERE email IN ('driver@titotr.ru', 'evgeny@titotr.ru');

-- All other users remain 'client' (default)

COMMIT;

-- Verification query
-- SELECT email, name, role FROM users ORDER BY role;
