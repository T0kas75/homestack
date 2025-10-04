#!/usr/bin/env bash
set -euo pipefail

SRC="/opt/homestack"
DST="$HOME/homestack-portfolio"

echo "[i] Exporting sanitized portfolio to: $DST"
rm -rf "$DST"
mkdir -p "$DST" "$DST/config" "$DST/scripts" "$DST/env" "$DST/.github/workflows"

# 1) docker-compose.yml
if [[ -f "$SRC/docker-compose.yml" ]]; then
  cp "$SRC/docker-compose.yml" "$DST/docker-compose.yml"
fi

# 2) configs (safe configs only; exclude keys/certs). We copy /opt/homestack/config/**
if [[ -d "$SRC/config" ]]; then
  rsync -a --prune-empty-dirs \
    --exclude '*.key' --exclude '*.crt' --exclude '*.pem' \
    --exclude 'acme' \
    "$SRC/config/" "$DST/config/"
fi

# 3) scripts (assumes no hard-coded secrets inside; secrets should live in env files)
if [[ -d "$SRC/scripts" ]]; then
  rsync -a "$SRC/scripts/" "$DST/scripts/"
fi
chmod +x "$DST/scripts/"*.sh 2>/dev/null || true

# 4) Create *.example env files from .env and env/*.env (strip values)
make_example () {
  local in="$1" out="$2"
  awk -F'=' '
    /^[[:space:]]*#/ {next}
    /^[[:space:]]*$/ {next}
    /^[A-Za-z_][A-Za-z0-9_]*=/ {print $1"="}
  ' "$in" > "$out"
}

if [[ -f "$SRC/.env" ]]; then
  make_example "$SRC/.env" "$DST/.env.example"
fi
if [[ -d "$SRC/env" ]]; then
  for f in "$SRC"/env/*.env; do
    [[ -f "$f" ]] || continue
    base="$(basename "$f")"
    make_example "$f" "$DST/env/$base.example"
  done
fi
