#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Create user and database for Uptime Kuma
    CREATE USER $UPTIME_KUMA_DB_USER WITH PASSWORD '$UPTIME_KUMA_DB_PASSWORD';
    CREATE DATABASE uptime_kuma;
    GRANT ALL PRIVILEGES ON DATABASE uptime_kuma TO $UPTIME_KUMA_DB_USER;

    -- Create user and database for Beszel
    CREATE USER $BESZEL_DB_USER WITH PASSWORD '$BESZEL_DB_PASSWORD';
    CREATE DATABASE beszel;
    GRANT ALL PRIVILEGES ON DATABASE beszel TO $BESZEL_DB_USER;
EOSQL