#!/usr/bin/env bash

NAME="autoopsscaler"
SSH_DIR="$HOME/.ssh"
SSH_CONFIG="$SSH_DIR/config"
PLUGIN_NAME="aws"
PLUGIN_VERSION="6.44.0"
PLUGIN_ARCHIVE="pulumi-resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}-linux-amd64.tar.gz"
PLUGIN_URL="https://github.com/pulumi/pulumi-${PLUGIN_NAME}/releases/download/v${PLUGIN_VERSION}/${PLUGIN_ARCHIVE}"
PLUGIN_DIR=".pulumi-host-plugins/resource-${PLUGIN_NAME}-v${PLUGIN_VERSION}"

echo "Ensuring $SSH_DIR exists..."
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

echo "Ensuring Pulumi plugin $PLUGIN_NAME v$PLUGIN_VERSION is available..."
mkdir -p "$PLUGIN_DIR"
if [ ! -f "$PLUGIN_DIR/pulumi-resource-${PLUGIN_NAME}" ]; then
  wget -q --show-progress "$PLUGIN_URL"
  tar -xzf "$PLUGIN_ARCHIVE" -C "$PLUGIN_DIR"
  rm "$PLUGIN_ARCHIVE"
  echo "✔️ Plugin extracted to $PLUGIN_DIR"
else
  echo "✔️ Plugin already present"
fi

echo "Starting VM: $NAME..."
vagrant up

echo "Cleaning old SSH block for $NAME..."
if [ -f "$SSH_CONFIG" ]; then
  sed -i.bak "/^Host $NAME\$/,/^Host /{/^Host $NAME\$/!{/^Host /!d}}" "$SSH_CONFIG"
fi

echo "Adding fresh SSH config for $NAME..."
vagrant ssh-config | sed "s/^Host default/Host $NAME/" >> "$SSH_CONFIG"
chmod 600 "$SSH_CONFIG"

KEY_PATH=$(awk "/^Host $NAME\$/,/^Host /{ if (/IdentityFile/) print \$2 }" "$SSH_CONFIG" | head -n1)
if [[ -n "$KEY_PATH" && -f "$KEY_PATH" ]]; then
  chmod 600 "$KEY_PATH"
  echo "✔️ Secured $KEY_PATH"
else
  echo "⚠️ Warning: No private key found for $NAME"
fi

echo "Installing VS Code extensions..."
code --install-extension ms-vscode-remote.remote-ssh

echo "Verifying SSH..."
ssh -q "$NAME" exit && echo "✔️ SSH works!" || { echo "❌ SSH failed."; exit 1; }

echo "Reloading with plugin provisioner and opening VS Code..."
vagrant reload --provision
code --folder-uri "vscode-remote://ssh-remote+$NAME/vagrant"
