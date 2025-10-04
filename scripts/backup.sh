#!/usr/bin/env bash
set -euo pipefail

cd /opt/homestack

# Avoid overlapping runs (e.g., slow network)
exec 9>/opt/homestack/.backup.lock
flock -n 9 || { echo "[backup] another run is in progress, exiting"; exit 0; }

echo "[backup] $(date -Iseconds) start"

# 1) DB dump (owned by your user; atomic)
docker compose run --rm --user "$(id -u tokas):$(id -g tokas)" dumpdb

# 2) Restic backup + retention
docker compose run --rm restic

echo "[backup] $(date -Iseconds) done"


find /opt/homestack/backups -maxdepth 1 -name 'db-*.sql.gz' -mtime +14 -delete

