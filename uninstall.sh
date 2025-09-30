#!/usr/bin/env bash

set -e

echo "Uninstalling Apidog..."

# Function to find the Apidog AppImage
function find_apidog_appimage() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        local appimage=$(find "$dir" -name "apidog.appimage" -print -quit 2>/dev/null)
        if [ -n "$appimage" ]; then
            echo "$appimage"
            return 0
        fi
    done
    return 1
}

# Remove the Apidog AppImage
apidog_appimage=$(find_apidog_appimage)
if [ -n "$apidog_appimage" ]; then
    echo "Removing Apidog AppImage..."
    rm -f "$apidog_appimage"
else
    echo "Apidog AppImage not found."
fi

# Remove the apidog script from ~/.local/bin
echo "Removing Apidog script..."
rm -f "$HOME/.local/bin/apidog"

# Remove icons
echo "Removing Apidog icons..."
find "$HOME/.local/share/icons/hicolor" -name "apidog.png" -delete

# Remove desktop file
echo "Removing Apidog desktop file..."
rm -f "$HOME/.local/share/applications/apidog.desktop"

echo "Apidog has been uninstalled."

# Optionally, ask the user if they want to remove configuration files
read -p "Do you want to remove Apidog configuration files? (y/N) " remove_config
if [[ $remove_config =~ ^[Yy]$ ]]; then
    echo "Removing Apidog configuration files..."
    rm -rf "$HOME/.config/Apidog"
    echo "Configuration files removed."
fi

echo "Uninstallation complete."

