-- Create test database if it doesn't exist
SELECT 'CREATE DATABASE atslite_test' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'atslite_test')\gexec

-- Create extensions if they don't exist
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "unaccent";