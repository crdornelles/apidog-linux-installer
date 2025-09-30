#!/usr/bin/env bash

set -e

# URL of the apidog.sh script in the GitHub repository
APIDOG_SCRIPT_URL="https://raw.githubusercontent.com/crdornelles/apidog-linux-installer/main/apidog.sh"

# Local bin directory
LOCAL_BIN="$HOME/.local/bin"

# Create ~/.local/bin if it doesn't exist
mkdir -p "$LOCAL_BIN"

# Download apidog.sh and save it as 'apidog' in ~/.local/bin
echo "Downloading Apidog installer script..."
curl -fsSL "$APIDOG_SCRIPT_URL" -o "$LOCAL_BIN/apidog"

# Make the script executable
chmod +x "$LOCAL_BIN/apidog"

echo "Apidog installer script has been placed in $LOCAL_BIN/apidog"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
    echo "Warning: $LOCAL_BIN is not in your PATH."
    echo "To add it, run this command or add it to your shell profile:"
    echo "export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# Run apidog --update to download and install Apidog
echo "Downloading and installing Apidog..."
"$LOCAL_BIN/apidog" --update "$@"

echo "Installation complete. You can now run 'apidog' to start Apidog."

