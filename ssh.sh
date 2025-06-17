#!/usr/bin/env bash
set -euo pipefail

NAME="AutoOpsScaler"

# 1️⃣ Start the VM
vagrant up

# 2️⃣ Safe: remove old AutoOpsScaler block, add fresh one
grep -v "Host $NAME" ~/.ssh/config 2>/dev/null > ~/.ssh/config.tmp || true
mv ~/.ssh/config.tmp ~/.ssh/config
vagrant ssh-config | sed "s/Host default/Host $NAME/" >> ~/.ssh/config

# 3️⃣ Open VS Code connected to the VM
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
