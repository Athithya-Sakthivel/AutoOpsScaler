#!/usr/bin/env bash


### CONFIGURATION ###
NAME="autoopsscaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"

# Pulumi CLI version (optional, installs if missing)
PULUMI_VERSION="4.45.2"
PULUMI_INSTALLER="https://get.pulumi.com/?release=v${PULUMI_VERSION}&source=script"

# AWS plugin version
PLUGIN_NAME="aws"
PLUGIN_VERSION="6.44.0"

# Determine OS/ARCH for plugin URL
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) ARCH="amd64" ;;
  arm64|aarch64) ARCH="arm64" ;;
esac

# Archive & cache paths
PLUGIN_ARCHIVE="pulumi-resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-${OS}-${ARCH}.tar.gz"
PLUGIN_URL="https://github.com/pulumi/pulumi-${PLUGIN_NAME}/releases/download/v${PLUGIN_VERSION}/${PLUGIN_ARCHIVE}"
HOST_CACHE_DIR="$HOME/.pulumi-host-plugins/resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-${OS}-${ARCH}"

### 1) SSH dir for host ###
echo "→ Ensuring SSH dir: $SSH_DIR"
mkdir -p "$SSH_DIR" && chmod 700 "$SSH_DIR"

### 2) Install Pulumi CLI if missing ###
if ! command -v pulumi >/dev/null 2>&1; then
  echo "→ Installing Pulumi CLI v${PULUMI_VERSION}"
  curl -fsSL "$PULUMI_INSTALLER" | bash
  export PATH="$HOME/.pulumi/bin:$PATH"
else
  echo "→ Pulumi CLI present: $(pulumi version)"
fi

### 3) Pre‑cache AWS plugin on host ###
echo "→ Pre‑caching Pulumi plugin $PLUGIN_NAME v$PLUGIN_VERSION for $OS/$ARCH"
mkdir -p "$HOST_CACHE_DIR"
if [ ! -f "$HOST_CACHE_DIR/pulumi-resource-${PLUGIN_NAME}" ]; then
  echo "   • Downloading $PLUGIN_URL"
  curl -# -L "$PLUGIN_URL" -o "$PLUGIN_ARCHIVE"
  echo "   • Extracting to $HOST_CACHE_DIR"
  tar -xzf "$PLUGIN_ARCHIVE" -C "$HOST_CACHE_DIR"
  rm -f "$PLUGIN_ARCHIVE"
  echo "   ✔ Cached plugin"
else
  echo "   ✔ Plugin already cached"
fi

### 4) Bring up & provision VM ###
echo "→ Starting VM: $NAME"
vagrant up --provision

### 5) Inject plugins into VM ###
echo "→ Injecting Pulumi plugins into VM"
vagrant ssh -c "mkdir -p ~/.pulumi/plugins && cp -r ~/.pulumi-host-plugins/* ~/.pulumi/plugins/ || true"

### 6) Update host SSH config ###
echo "→ Updating SSH config for host entry '$NAME'"
if grep -q "^Host $NAME\$" "$SSH_CONFIG" 2>/dev/null; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"
KEY_PATH="$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)"
[ -f "$KEY_PATH" ] && chmod 600 "$KEY_PATH" && echo "   ✔ Secured SSH key"

### 7) (Optional) VS Code extensions ###
if command -v code >/dev/null 2>&1; then
  echo "→ Installing VS Code extensions..."
  code --install-extension ms-vscode-remote.remote-ssh
  code --install-extension ms-python.python
  code --install-extension ms-azuretools.vscode-docker
  code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
  code --install-extension charliermarsh.ruff
  code --install-extension necatiarslan.aws-s3-vscode-extension
  echo "   ✔ Extensions installed"
fi

### 8) Verify & Open ###
echo "→ Verifying SSH to $NAME"
if ssh -q "$NAME" exit; then
  echo "   ✔ SSH OK"
  echo "→ Reloading VM to pick up plugins and opening VS Code"
  vagrant reload --provision
  code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
else
  echo "   ❌ SSH failed"
  exit 1
fi
