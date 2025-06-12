# Regenerate all infra from config for dev and prod


#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"

CONFIG_FILE="config/${ENV}_config.yaml"
PYTHON_BIN="python3.10"

echo "🔄 Regenerating infrastructure for [${ENV}]..."

# Check config exists
if [[ ! -f "${CONFIG_FILE}" ]]; then
  echo "❌ Config file not found: ${CONFIG_FILE}"
  exit 1
fi

# Step 1: Clear previous renders
echo "🧹 Cleaning old base_infra/ render..."
rm -rf base_infra/
mkdir -p base_infra/

# Step 2: Load + Validate
echo "🔍 Validating config..."
${PYTHON_BIN} config/generate_infra/main.py --env "${ENV}" --validate

# Step 3: Render all
echo "🛠 Rendering..."
${PYTHON_BIN} config/generate_infra/main.py --env "${ENV}" --render

echo "✅ Done."


