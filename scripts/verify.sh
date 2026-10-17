#!/usr/bin/env bash
set -u

BASE="/opt/loki"
BIND_IP="${1:-10.70.16.235}"

echo "=== Container status ==="
docker compose -f "$BASE/compose.yaml" ps

echo
echo "=== Loki readiness ==="
curl --max-time 5 -sS -i http://127.0.0.1:3100/ready || true

echo
echo "=== Loki logs ==="
docker logs --tail 50 loki || true

echo
echo "=== Disk usage ==="
df -h /
du -sh "$BASE/data" 2>/dev/null || true

echo
echo "=== LAN readiness ==="
curl --max-time 5 -sS -i "http://${BIND_IP}:3100/ready" || true
