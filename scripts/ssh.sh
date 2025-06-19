#!/usr/bin/env bash
# scripts/bootstrap_vm.sh

# CONFIG
NAME="autoopsscaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo "→ Ensuring SSH directory exists: $SSH_DIR"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ─────────────────────────────────────────────
# STEP 0: Required CLI checks
REQUIRED_CMDS=(curl tar vagrant ssh scp code sed awk)
for cmd in "${REQUIRED_CMDS[@]}"; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo " Required command '$cmd' not found. Please install it."
    exit 1
  fi
done

# ─────────────────────────────────────────────
# STEP 1: Start Vagrant VM
echo "→ Starting Vagrant VM: $NAME..."
vagrant up

# ─────────────────────────────────────────────
# STEP 2: SSH Config Setup
echo "→ Cleaning old SSH block for $NAME in $SSH_CONFIG"
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG" || true
fi

echo "→ Adding fresh SSH config block"
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

# Fix permissions on SSH private key
KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1 || true)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo " Secured SSH private key at $KEY_PATH"
else
  echo " Warning: SSH private key for $NAME not found or invalid."
fi

# ─────────────────────────────────────────────
# STEP 3: VSCode Remote SSH Extension
echo "→ Installing VS Code Remote SSH extension (if not present)..."
code --install-extension ms-vscode-remote.remote-ssh --force || true

# ─────────────────────────────────────────────
# STEP 4: Verify SSH connectivity
echo "→ Verifying SSH connectivity to $NAME..."
if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$NAME" exit; then
  echo " SSH connectivity verified!"
else
  echo " SSH connectivity failed. Please troubleshoot SSH config or VM status."
  exit 1
fi

# ─────────────────────────────────────────────
# STEP 5: Reload Vagrant and Provision
echo "→ Reloading and provisioning VM..."
vagrant reload --provision

# ─────────────────────────────────────────────
# STEP 6: Open VS Code Workspace
echo "→ Opening VS Code with Remote SSH workspace..."
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"

# ─────────────────────────────────────────────
echo " All done. Terraform-ready VM environment is live!"

exit 0
