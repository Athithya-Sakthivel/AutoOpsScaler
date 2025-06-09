#!/usr/bin/env bash

# login.sh - Idempotent GitHub login + Git config script for dev containers and WSL
# Logs out existing gh session and does clean login with single input run.

set -euo pipefail
IFS=$'\n\t'

# Logging helpers
log() { echo -e "\e[32m[+]\e[0m $1"; }
err() { echo -e "\e[31m[!]\e[0m $1" >&2; }

# Dependency check
command -v gh >/dev/null 2>&1 || { err "Missing gh CLI. Install with: sudo apt install gh"; exit 1; }
command -v git >/dev/null 2>&1 || { err "Missing Git. Install with: sudo apt install git"; exit 1; }

# Always logout before login to ensure idempotency
if gh auth status >/dev/null 2>&1; then
  log "Logging out existing GitHub session..."
  gh auth logout -h github.com -s all >/dev/null 2>&1 || true
fi

# Prompt user for inputs just once
echo -n "Enter your GitHub username: "
read -r GH_USERNAME
echo -n "Enter your GitHub email: "
read -r GH_EMAIL
echo -n "Get your PAT if not already: https://github.com/settings/tokens/new\n"
echo -n "Enter your GitHub Personal Access Token (PAT): "
read -rs GH_PAT
echo ""

# Do GitHub CLI login with token
echo "$GH_PAT" | gh auth login --with-token || { err "GitHub CLI login failed. Check token."; exit 1; }
log "GitHub CLI authenticated."

# Git config: set only if unset
GIT_NAME=$(git config --global user.name || echo "")
GIT_EMAIL=$(git config --global user.email || echo "")

if [[ -z "$GIT_NAME" ]]; then
  git config --global user.name "$GH_USERNAME"
  log "Git global username set to: $GH_USERNAME"
else
  log "Git global username already set: $GIT_NAME"
fi

if [[ -z "$GIT_EMAIL" ]]; then
  git config --global user.email "$GH_EMAIL"
  log "Git global email set to: $GH_EMAIL"
else
  log "Git global email already set: $GIT_EMAIL"
fi

# Persist GitHub credentials in dev container
git config --global credential.helper store

# Final validation
if gh auth status >/dev/null 2>&1; then
  log "✅ Login and Git config complete."
else
  err "Post-login validation failed. Retry."
  exit 1
fi
