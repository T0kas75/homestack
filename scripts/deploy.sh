#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="/opt/homestack"

echo "[1/5] Ensure target dirs"
sudo mkdir -p "$TARGET"
sudo mkdir -p "$TARGET/env" "$TARGET/config" "$TARGET/scripts"

echo "[2/5] Sync files"
# compose → root of TARGET (brings docker-compose.yml etc.)
sudo rsync -a --delete "$SRC/compose/" "$TARGET/"

# env/ and config/ are optional in the repo; copy only if present
if [[ -d "$SRC/env" ]]; then
  sudo rsync -a --delete "$SRC/env/" "$TARGET/env/"
fi
if [[ -d "$SRC/config" ]]; then
  sudo rsync -a --delete "$SRC/config/" "$TARGET/config/"
fi
if [[ -d "$SRC/scripts" ]]; then
  sudo rsync -a --delete "$SRC/scripts/" "$TARGET/scripts/"
fi

echo "[3/5] Refresh .env"
if [[ -f "$TARGET/env/base.env" ]]; then
  sudo cp -f "$TARGET/env/base.env" "$TARGET/.env"
fi

echo "[4/5] Validate & start"
cd "$TARGET"
docker compose -f docker-compose.yml config >/dev/null
docker compose -f docker-compose.yml pull
docker compose -f docker-compose.yml up -d --remove-orphans

echo "[5/5] Status"
docker compose -f docker-compose.yml ps
