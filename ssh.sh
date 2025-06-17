#!/usr/bin/env bash
set -euo pipefail

NAME="AutoOpsScaler"
CONFIG=$(vagrant ssh-config)

HOSTNAME=$(echo "$CONFIG" | awk '/HostName/ {print $2}')
USER=$(echo "$CONFIG" | awk '/User / {print $2}')
PORT=$(echo "$CONFIG" | awk '/Port/ {print $2}')
IDENTITYFILE=$(echo "$CONFIG" | awk '/IdentityFile/ {print $2; exit}')

# Normalize path for Windows OpenSSH
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
  # Convert C:/ to /c/ style for mingw/openssh
  IDENTITYFILE=$(echo "$IDENTITYFILE" | sed 's#^\([A-Za-z]\):#/\\L\1/#')
fi

cat > ~/.ssh/config <<EOF
Host $NAME
  HostName $HOSTNAME
  User $USER
  Port $PORT
  IdentityFile $IDENTITYFILE
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  IdentitiesOnly yes
EOF

echo "✅ SSH config ready for $NAME"
echo "👉 You can now run: ssh $NAME"
echo "👉 Or: code --folder-uri \"vscode-remote://ssh-remote+$NAME/vagrant\""
