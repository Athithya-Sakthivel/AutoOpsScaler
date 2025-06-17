#!/usr/bin/env bash

NAME="AutoOpsScaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo " Ensuring $SSH_DIR exists..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo " Starting VM with STATIC key..."
vagrant up

echo " Removing old config for $NAME..."
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi

echo " Adding fresh config for $NAME..."
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"

echo " Securing SSH config..."
chmod 600 "$SSH_CONFIG"

echo " Securing static Vagrant private key..."
KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔ $KEY_PATH secured"
else
  echo " Warning: Could not find private key for $NAME"
fi

echo " Installing VS Code Remote SSH extensions..."
code --install-extension ms-vscode-remote.remote-ssh

echo " Testing SSH connection..."
ssh -o StrictHostKeyChecking=no "$NAME" exit && echo "✔️ SSH works!" || { echo "❌ SSH failed. Check your config."; exit 1; }

echo "🚀 Opening VS Code Remote SSH: $NAME"
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
