#!/usr/bin/env bash
set -Eeuo pipefail

if [[ "$EUID" -ne 0 ]]; then
  echo "Run this script with sudo."
  exit 1
fi

SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="/opt/loki"

command -v docker >/dev/null || {
  echo "Docker is not installed."
  exit 1
}

docker compose version >/dev/null

if [[ ! -f "$SOURCE_DIR/.env" ]]; then
  cp "$SOURCE_DIR/.env.example" "$SOURCE_DIR/.env"
  echo "Created .env. Check LOKI_BIND_IP before continuing."
fi

BIND_IP="$(sed -n 's/^LOKI_BIND_IP=//p' "$SOURCE_DIR/.env" | tail -n1 | tr -d '[:space:]')"

if [[ -z "$BIND_IP" ]]; then
  echo "LOKI_BIND_IP is missing from .env"
  exit 1
fi

if ! ip -o addr show | awk '{print $4}' | cut -d/ -f1 | grep -Fxq "$BIND_IP"; then
  echo "ERROR: $BIND_IP is not assigned to this server."
  echo "Edit $SOURCE_DIR/.env and set the correct VM IP."
  exit 1
fi

mkdir -p "$TARGET_DIR/config" "$TARGET_DIR/data"
mkdir -p "$TARGET_DIR/scripts"

cp "$SOURCE_DIR/compose.yaml" "$TARGET_DIR/compose.yaml"
cp "$SOURCE_DIR/config/loki.yaml" "$TARGET_DIR/config/loki.yaml"
cp "$SOURCE_DIR/.env" "$TARGET_DIR/.env"
cp "$SOURCE_DIR/scripts/verify.sh" "$TARGET_DIR/scripts/verify.sh"

chown -R 10001:10001 "$TARGET_DIR/data"
chmod 0644 "$TARGET_DIR/compose.yaml" \
  "$TARGET_DIR/config/loki.yaml" "$TARGET_DIR/.env"
chmod 0755 "$TARGET_DIR/scripts/verify.sh"

cd "$TARGET_DIR"
docker compose config
docker compose pull
docker compose up -d

echo "Loki deployment started."
echo "Check: curl -i http://127.0.0.1:3100/ready"
