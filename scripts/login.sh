#!/usr/bin/env bash

# login.sh - Fully automated GitHub login + Git config script for Ubuntu VM

set -euo pipefail
IFS=$'\n\t'

# Logging helpers
log() { echo -e "\e[32m[+]\e[0m $1"; }
err() { echo -e "\e[31m[!]\e[0m $1" >&2; }

# Dependency check
command -v gh >/dev/null 2>&1 || { err "Missing gh CLI. Install with: sudo apt install gh"; exit 1; }
command -v git >/dev/null 2>&1 || { err "Missing Git. Install with: sudo apt install git"; exit 1; }

# Accept arguments or environment variables, or prompt if missing
GH_USERNAME="${1:-${GH_USERNAME:-}}"
GH_EMAIL="${2:-${GH_EMAIL:-}}"
GH_PAT="${3:-${GH_PAT:-}}"

if [[ -z "$GH_USERNAME" ]]; then
  read -rp "Enter your GitHub username: " GH_USERNAME
fi
if [[ -z "$GH_EMAIL" ]]; then
  read -rp "Enter your GitHub email: " GH_EMAIL
fi
if [[ -z "$GH_PAT" ]]; then
  echo "👉 If you don't have a PAT, generate one here:"
  echo "   https://github.com/settings/tokens/new"
  read -rsp "Enter your GitHub Personal Access Token (PAT): " GH_PAT
  echo ""
fi

# Always logout before login to ensure idempotency
if gh auth status >/dev/null 2>&1; then
  log "Logging out existing GitHub session..."
  gh auth logout -h github.com -s all >/dev/null 2>&1 || true
fi

# Do GitHub CLI login with token
echo "$GH_PAT" | gh auth login --with-token || { err "GitHub CLI login failed. Check token."; exit 1; }
log "GitHub CLI authenticated."

# Always set Git config
git config --global user.name "$GH_USERNAME"
log "Git global username set to: $GH_USERNAME"

git config --global user.email "$GH_EMAIL"
log "Git global email set to: $GH_EMAIL"

# Persist GitHub credentials
git config --global credential.helper store

# Final validation
if gh auth status >/dev/null 2>&1; then
  log "✅ Login and Git config complete."
else
  err "Post-login validation failed. Retry."
  exit 1
fi