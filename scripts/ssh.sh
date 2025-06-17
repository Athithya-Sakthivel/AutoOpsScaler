#!/usr/bin/env bash
set -euo pipefail

NAME="AutoOpsScaler"
SSH_CONFIG="$HOME/.ssh/config"
SSH_DIR="$HOME/.ssh"

# 0️⃣ Make sure ~/.ssh exists and is locked down
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 1️⃣ Start the VM (will reuse it if already running)
vagrant up

# 2️⃣ Remove any old block for this host
#    and write a clean ssh-config entry
grep -v "Host $NAME" "$SSH_CONFIG" 2>/dev/null > "${SSH_CONFIG}.tmp" || true
mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"
vagrant ssh-config \
  | sed -E "s/^Host default/Host $NAME/" \
  >> "$SSH_CONFIG"

# 3️⃣ Secure your SSH config
chmod 600 "$SSH_CONFIG"

# 4️⃣ Secure the Vagrant private key
##
#    Extract the IdentityFile path from the config block we just added:
KEY_PATH=$(awk "/^Host $NAME/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
fi

# 5️⃣ Install (or reinstall) your VS Code Remote‑SSH extension + Python, Docker, etc.
code --install-extension ms-vscode-remote.remote-ssh@latest
code --install-extension charliermarsh.ruff@latest
code --install-extension necatiarslan.aws-s3-vscode-extension@latest
code --install-extension ms-python.python@latest
code --install-extension ms-azuretools.vscode-docker@latest
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools@latest

# 6️⃣ Finally, launch VS Code into the Remote‑SSH session
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
