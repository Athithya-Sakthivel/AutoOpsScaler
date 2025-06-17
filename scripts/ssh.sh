#!/usr/bin/env bash
set -euo pipefail
rm -rf ~/.config/VirtualBox       # Linux
rm -rf ~/Library/VirtualBox       # macOS
NAME="AutoOpsScaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo " Ensuring $SSH_DIR exists and is secure..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo " Starting VM: $NAME..."
vagrant up

echo " Cleaning up old SSH config block for $NAME..."
# Remove old block safely: sed deletes from "Host NAME" to next "Host " or EOF
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi

echo " Adding fresh SSH config for $NAME..."
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"

echo " Securing SSH config file..."
chmod 600 "$SSH_CONFIG"

echo " Securing Vagrant private key..."
KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔️ Secured $KEY_PATH"
else
  echo "⚠️ Warning: Could not find private key path for $NAME"
fi

echo " Installing VS Code extensions..."
code --install-extension ms-vscode-remote.remote-ssh
code --install-extension charliermarsh.ruff
code --install-extension NecatiARSLAN.aws-s3-vscode-extension
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

echo " Verifying SSH connection..."
ssh -q "$NAME" exit && echo "✔️ SSH works!" || { echo "❌ SSH failed — check your config."; exit 1; }

echo " Opening VS Code with Remote SSH: $NAME"
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"



