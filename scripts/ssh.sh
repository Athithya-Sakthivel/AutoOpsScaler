#!/usr/bin/env bash
set -euo pipefail

# CONFIG
NAME="autoopsscaler"
PLUGIN_NAME="aws"
PLUGIN_VERSION="6.44.0"
PLUGIN_ARCHIVE="pulumi-resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-linux-amd64.tar.gz"
PLUGIN_URL="https://github.com/pulumi/pulumi-${PLUGIN_NAME}/releases/download/v${PLUGIN_VERSION}/${PLUGIN_ARCHIVE}"
PLUGIN_DIR="$HOME/.pulumi-host-plugins/resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-linux-amd64"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo "→ Ensuring SSH dir: $SSH_DIR"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ─────────────────────────────────────────
# PRO TIP: Check for required CLI tools
for cmd in curl tar vagrant ssh code; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Required command '$cmd' not found. Please install it first."
    exit 1
  fi
done

# ─────────────────────────────────────────
# STEP 1: Install Pulumi plugin for Linux (used inside VM)
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "→ Pre‑caching Pulumi plugin $PLUGIN_NAME v$PLUGIN_VERSION for Linux/amd64"

  # Download with fallback
  if command -v curl >/dev/null 2>&1; then
    curl -# -L "$PLUGIN_URL" -o "$PLUGIN_ARCHIVE"
  elif command -v wget >/dev/null 2>&1; then
    wget --progress=bar:force "$PLUGIN_URL" -O "$PLUGIN_ARCHIVE"
  else
    echo "❌ Neither curl nor wget found. Install one of them."; exit 1
  fi

  mkdir -p "$PLUGIN_DIR"
  echo "→ Extracting to $PLUGIN_DIR"
  tar -xzf "$PLUGIN_ARCHIVE" -C "$PLUGIN_DIR"
  rm -f "$PLUGIN_ARCHIVE"
  echo "✔️ Plugin extracted to $PLUGIN_DIR"
else
  echo "✔️ Pulumi plugin already available at $PLUGIN_DIR"
fi

# ─────────────────────────────────────────
# STEP 2: Start VM and configure SSH
echo "→ Starting VM: $NAME..."
vagrant up

echo "→ Cleaning old SSH block for $NAME in $SSH_CONFIG"
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi

echo "→ Adding fresh SSH config block"
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔️ Secured SSH key at $KEY_PATH"
else
  echo "⚠️ Warning: No private key found for $NAME"
fi

# ─────────────────────────────────────────
# STEP 3: VSCode Remote setup
echo "→ Installing VS Code extensions..."
code --install-extension ms-vscode-remote.remote-ssh

# ─────────────────────────────────────────
# STEP 4: Test SSH connection
echo "→ Verifying SSH connectivity..."
ssh -q "$NAME" exit && echo "✔️ SSH works!" || { echo "❌ SSH failed."; exit 1; }

# ─────────────────────────────────────────
# STEP 5: Inject plugin into VM
echo "→ Injecting Pulumi plugin into VM..."
ssh "$NAME" 'mkdir -p ~/.pulumi/plugins/resource-aws-v6.44.0'
scp "$PLUGIN_DIR/pulumi-resource-${PLUGIN_NAME}" "$NAME:~/.pulumi/plugins/resource-aws-v6.44.0/"
echo "✔️ Pulumi plugin injected inside VM."

# ─────────────────────────────────────────
# STEP 6: Open VSCode in Remote
echo "→ Opening VS Code with Remote SSH workspace..."
vagrant reload --provision
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
