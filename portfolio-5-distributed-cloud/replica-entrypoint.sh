#!/bin/bash
set -e

echo "=== EquityPay Standby Replica Entrypoint Initializing ==="

PRIMARY_HOST="${PRIMARY_HOST:-primary}"
PRIMARY_PORT="${PRIMARY_PORT:-5432}"
REPLICA_USER="${REPLICA_USER:-replicator}"
REPLICATION_PASSWORD="${REPLICATION_PASSWORD:-${REPLICA_PASSWORD:-replica_secure_pass}}"
PGDATA="${PGDATA:-/var/lib/postgresql/data/pgdata}"

# Ensure proper permissions on the data directory
mkdir -p "$PGDATA"
chmod 700 "$PGDATA"

# Wait until primary database is ready and accepting connections
echo "Waiting for primary database ($PRIMARY_HOST:$PRIMARY_PORT) to accept replication connections..."
until pg_isready -h "$PRIMARY_HOST" -p "$PRIMARY_PORT" -U "$REPLICA_USER"; do
  echo "Primary database not ready yet. Retrying in 2 seconds..."
  sleep 2
done

echo "Primary database is active and accepting connections."

# Bootstrap standby replica from primary if PGDATA is empty
if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Standby data directory is uninitialized. Initiating pg_basebackup stream..."
  rm -rf "${PGDATA:?}"/*

  export PGPASSWORD="$REPLICATION_PASSWORD"
  pg_basebackup \
    -h "$PRIMARY_HOST" \
    -p "$PRIMARY_PORT" \
    -U "$REPLICA_USER" \
    -D "$PGDATA" \
    -Fp \
    -Xs \
    -P \
    -R \
    --slot="${REPLICATION_SLOT:-equitypay_standby_slot}" \
    --create-slot

  unset PGPASSWORD
  chown -R postgres:postgres "$PGDATA"
  chmod 700 "$PGDATA"
  echo "=== pg_basebackup completed successfully. Standby replication configured. ==="
else
  echo "Existing data files detected in $PGDATA. Skipping base backup."
  chown -R postgres:postgres "$PGDATA"
fi

# Hand over process control to postgres user in hot standby mode
echo "Starting PostgreSQL in standby mode..."
exec gosu postgres postgres -c hot_standby=on "$@"

