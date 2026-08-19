#!/bin/bash

# PostgreSQL initialization script for Synapse

set -e

# Create Synapse user and database
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
    CREATE DATABASE ${POSTGRES_DB};
    GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
    \c ${POSTGRES_DB}
    GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};
EOSQL

# Create required extensions
echo "Creating required PostgreSQL extensions..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS plpgsql;
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EOSQL

# Optimize PostgreSQL for Synapse
echo "Optimizing PostgreSQL for Synapse..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER SYSTEM SET shared_buffers = '1GB';
    ALTER SYSTEM SET effective_cache_size = '3GB';
    ALTER SYSTEM SET maintenance_work_mem = '256MB';
    ALTER SYSTEM SET work_mem = '16MB';
    ALTER SYSTEM SET random_page_cost = '1.1';
    ALTER SYSTEM SET max_connections = '200';
    ALTER SYSTEM SET max_worker_processes = '8';
    ALTER SYSTEM SET max_parallel_workers_per_gather = '4';
    ALTER SYSTEM SET max_parallel_workers = '8';
    ALTER SYSTEM SET max_wal_size = '2GB';
    ALTER SYSTEM SET min_wal_size = '512MB';
    ALTER SYSTEM SET checkpoint_completion_target = '0.9';
EOSQL

echo "PostgreSQL initialization completed successfully."