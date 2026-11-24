#!/usr/bin/env bash
# Despliegue maestro reproducible - Homelab Istmo SOC (Alcaldía de Valle Escondido)
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "=== Desplegando stacks del Homelab Istmo SOC (Reto 6 - AVE) ==="

for compose in "$BASE_DIR"/docker/*/docker-compose.y*ml "$BASE_DIR"/docker/*/compose.y*ml; do
    [[ -f "$compose" ]] || continue
    stack_dir="$(dirname "$compose")"
    stack_name="$(basename "$stack_dir")"
    echo "[+] Levantando stack: $stack_name"
    (cd "$stack_dir" && docker compose up -d)
done

echo "[+] Estado final de servicios:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
