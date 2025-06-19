#!/usr/bin/env bash
# CONFIG
NAME="autoopsscaler"
PLUGIN_NAME="aws"
PLUGIN_VERSION="6.83.0"
PLUGIN_ARCHIVE="pulumi-resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-linux-amd64.tar.gz"
PLUGIN_URL="https://github.com/pulumi/pulumi-${PLUGIN_NAME}/releases/download/v${PLUGIN_VERSION}/${PLUGIN_ARCHIVE}"
PLUGIN_DIR="$HOME/.pulumi-host-plugins/resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-linux-amd64"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

echo "→ Ensuring SSH dir: $SSH_DIR"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# ─────────────────────────────────────────────
# PRO TIP: Ensure required CLI tools are available
for cmd in curl tar vagrant ssh scp code sed awk; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "❌ Required command '$cmd' not found. Please install it."
    exit 1
  fi
done

# ─────────────────────────────────────────────
# STEP 1: Pre-cache Pulumi plugin for Linux (used inside VM)
if [ ! -d "$PLUGIN_DIR" ]; then
  echo "→ Pre-caching Pulumi plugin $PLUGIN_NAME v$PLUGIN_VERSION for Linux/amd64"

  if [ ! -f "$PLUGIN_ARCHIVE" ]; then
    curl -# -L "$PLUGIN_URL" -o "$PLUGIN_ARCHIVE"
  else
    echo "→ Plugin archive $PLUGIN_ARCHIVE already downloaded"
  fi

  mkdir -p "$PLUGIN_DIR"
  echo "→ Extracting to $PLUGIN_DIR"
  tar -xzf "$PLUGIN_ARCHIVE" -C "$PLUGIN_DIR"
  rm -f "$PLUGIN_ARCHIVE"
  echo "✔️ Plugin extracted to $PLUGIN_DIR"
else
  echo "✔️ Pulumi plugin already available at $PLUGIN_DIR"
fi

# ─────────────────────────────────────────────
# STEP 2: Start VM and configure SSH
echo "→ Starting VM: $NAME..."
vagrant up

echo "→ Cleaning old SSH block for $NAME in $SSH_CONFIG"
if [ -f "$SSH_CONFIG" ]; then
  # Remove old host block safely
  # This sed command deletes the block starting with Host $NAME until next Host or EOF
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG" || true
fi

echo "→ Adding fresh SSH config block"
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1 || true)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔️ Secured SSH key at $KEY_PATH"
else
  echo "⚠️ Warning: No private key found for $NAME"
fi

# ─────────────────────────────────────────────
# STEP 3: VSCode Remote extensions
echo "→ Installing VS Code Remote SSH extension..."
code --install-extension ms-vscode-remote.remote-ssh --force || true

# ─────────────────────────────────────────────
# STEP 4: Verify SSH connection
echo "→ Verifying SSH connectivity to $NAME..."
if ssh -q -o BatchMode=yes -o ConnectTimeout=5 "$NAME" exit; then
  echo "✔️ SSH connectivity verified!"
else
  echo "❌ SSH connectivity failed. Check your SSH config and VM status."
  exit 1
fi

# ─────────────────────────────────────────────
# STEP 5: Inject plugin into VM
echo "→ Injecting Pulumi plugin into VM..."

REMOTE_PLUGIN_DIR=".pulumi/plugins/resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}"
ssh "$NAME" "mkdir -p ~/$REMOTE_PLUGIN_DIR"

# Ensure the exact plugin binary file exists
PLUGIN_BINARY_PATH="$PLUGIN_DIR/pulumi-resource-${PLUGIN_NAME}"
if [ ! -f "$PLUGIN_BINARY_PATH" ]; then
  echo "❌ Pulumi plugin binary not found at $PLUGIN_BINARY_PATH"
  echo "Available files in plugin dir:"
  ls -l "$PLUGIN_DIR"
  exit 1
fi

scp "$PLUGIN_BINARY_PATH" "$NAME:~/$REMOTE_PLUGIN_DIR/"
echo "✔️ Pulumi plugin injected inside VM."

# ─────────────────────────────────────────────
# STEP 6: Reload VM and open VSCode with Remote SSH
echo "→ Reloading VM and provisioning..."
vagrant reload --provision

echo "→ Opening VS Code with Remote SSH workspace..."
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"

# ─────────────────────────────────────────────
echo "→ All done. Your environment is ready."

exit 0
