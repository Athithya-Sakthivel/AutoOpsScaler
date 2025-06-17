#!/usr/bin/env bash
set -euo pipefail

NAME="AutoOpsScaler"

# 1️⃣ Start the VM
vagrant up

# 2️⃣ Safe: remove old AutoOpsScaler block, add fresh one
grep -v "Host $NAME" ~/.ssh/config 2>/dev/null > ~/.ssh/config.tmp || true
mv ~/.ssh/config.tmp ~/.ssh/config
vagrant ssh-config | sed "s/Host default/Host $NAME/" >> ~/.ssh/config

code --install-extension ms-vscode-remote.remote-ssh
# Install all recommended extensions locally for VS Code

code --install-extension charliermarsh.ruff
code --install-extension NecatiARSLAN.aws-s3-vscode-extension
code --install-extension ms-python.python
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools

code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
