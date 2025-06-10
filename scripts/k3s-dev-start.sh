#!/usr/bin/env bash
set -euo pipefail
echo "🔁 Starting K3s..."
nohup /usr/local/bin/k3s server --disable traefik > /var/log/k3s.log 2>&1 &
sleep 5
echo "✅ K3s should now be running"
