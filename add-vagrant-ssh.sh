#!/usr/bin/env bash
# One universal script — Linux, macOS, Windows Git Bash

set -euo pipefail

CONFIG="$(vagrant ssh-config 2>/dev/null || true)"
if [ -z "$CONFIG" ]; then
  echo "❌ Failed to run 'vagrant ssh-config'. Is your VM running?"
  exit 1
fi

HOSTNAME=$(echo "$CONFIG" | grep HostName | awk '{print $2}')
USER=$(echo "$CONFIG" | grep User | awk '{print $2}')
PORT=$(echo "$CONFIG" | grep Port | awk '{print $2}')
IDENTITYFILE=$(echo "$CONFIG" | grep IdentityFile | awk '{print $2}')

# 👉 If running in Git Bash, convert path for Windows SSH
if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32"* ]]; then
  IDENTITYFILE=$(cygpath -w "$IDENTITYFILE")
fi

SSH_BLOCK="Host my-vagrant-vm
  HostName $HOSTNAME
  User $USER
  Port $PORT
  IdentityFile $IDENTITYFILE
  StrictHostKeyChecking no"

mkdir -p ~/.ssh
SSH_CONFIG=~/.ssh/config

if ! grep -q "Host my-vagrant-vm" "$SSH_CONFIG" 2>/dev/null; then
  echo "$SSH_BLOCK" >> "$SSH_CONFIG"
  echo "✅ Added 'my-vagrant-vm' to $SSH_CONFIG"
else
  echo "ℹ️  'my-vagrant-vm' already exists. Skipping."
fi