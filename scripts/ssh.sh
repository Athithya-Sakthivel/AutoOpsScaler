#!/usr/bin/env bash
set -euo pipefail

NAME="AutoOpsScaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo "🔐 Ensuring $SSH_DIR exists and has secure permissions..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "🚀 Starting VM: $NAME..."
vagrant up

echo "🧹 Cleaning old SSH config for $NAME..."
# Remove old block: sed deletes from "Host NAME" up to next "Host " or EOF
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi

echo "➕ Adding fresh SSH config for $NAME..."
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"

echo "🔒 Securing SSH config file..."
chmod 600 "$SSH_CONFIG"

echo "🔑 Securing Vagrant private key..."
# Always extract IdentityFile fresh:
KEY_PATH=$(vagrant ssh-config | awk '/IdentityFile/ {print $2}' | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔️ Secured private key: $KEY_PATH"
else
  echo "⚠️ Could not find valid private key for $NAME!"
  exit 1
fi

echo "🧩 Installing VS Code extensions (skip if already installed)..."
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension charliermarsh.ruff
code --install-extension NecatiARSLAN.aws-s3-vscode-extension
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

echo "✅ Verifying SSH connection..."
if ssh -o StrictHostKeyChecking=no "$NAME" exit; then
  echo "✔️ SSH works!"
else
  echo "❌ SSH failed — please debug manually."
  exit 1
fi

echo "💻 Opening VS Code Remote SSH workspace..."
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
