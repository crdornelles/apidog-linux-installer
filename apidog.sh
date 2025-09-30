#!/usr/bin/env bash

set -e

ROOT=$(dirname "$(dirname "$(readlink -f $0)")")

function check_dependencies() {
    # Check for required dependencies
    if ! command -v unzip &>/dev/null; then
        echo "Error: unzip is required but not installed." >&2
        echo "Please install unzip using your package manager:" >&2
        echo "  - Debian/Ubuntu: sudo apt-get install unzip" >&2
        echo "  - Fedora: sudo dnf install unzip" >&2
        echo "  - Arch Linux: sudo pacman -S unzip" >&2
        exit 1
    fi
}

function check_fuse() {
    # Set command prefix based on whether we're root
    local cmd_prefix=""
    if [ "$EUID" -ne 0 ]; then
        cmd_prefix="sudo"
    fi

    # Check and install FUSE2 using the appropriate package manager
    if command -v apt-get &>/dev/null; then
        if ! dpkg -l | grep -q "^ii.*libfuse2 "; then
            echo "Installing libfuse2..."
            $cmd_prefix apt-get update
            $cmd_prefix apt-get install -y libfuse2
        else
            echo "libfuse2 is already installed."
        fi
    elif command -v dnf &>/dev/null; then
        if ! rpm -q fuse >/dev/null 2>&1; then
            echo "Installing fuse..."
            $cmd_prefix dnf install -y fuse
        else
            echo "fuse is already installed."
        fi
    elif command -v pacman &>/dev/null; then
        if ! pacman -Qi fuse2 >/dev/null 2>&1; then
            echo "Installing fuse2..."
            $cmd_prefix pacman -S fuse2
        else
            echo "fuse2 is already installed."
        fi
    else
        echo "Unsupported package manager. Please install libfuse2 manually."
        echo "You can install FUSE2 using your system's package manager:"
        echo "  - Debian/Ubuntu: ${cmd_prefix}apt-get install libfuse2"
        echo "  - Fedora: ${cmd_prefix}dnf install fuse"
        echo "  - Arch Linux: ${cmd_prefix}pacman -S fuse2"
        exit 1
    fi

    # Verify FUSE2 is functional
    if ! fusermount -V >/dev/null 2>&1; then
        echo "Warning: FUSE2 verification failed. AppImage may not run." >&2
        return 1
    fi
    echo "FUSE2 is ready."
}

function get_arch() {
    local arch=$(uname -m)
    if [ "$arch" == "x86_64" ]; then
        echo "x64"
    elif [ "$arch" == "aarch64" ]; then
        echo "arm64"
    else
        echo "Unsupported architecture: $arch" >&2
        exit 1
    fi
}

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

function get_install_dir() {
    local search_dirs=("$HOME/AppImages" "$HOME/Applications" "$HOME/.local/bin")
    for dir in "${search_dirs[@]}"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return 0
        fi
    done
    echo "No suitable installation directory found" >&2
    exit 1
}

function get_download_info() {
    local arch=$(get_arch)
    local file_arch="x86_64"
    if [ "$arch" = "arm64" ]; then
        file_arch="aarch64"
    fi

    # Apidog download URL - using the correct download URL
    local download_url="https://file-assets.apidog.com/download/Apidog-linux-latest.zip"
    local version="latest"

    echo "URL=$download_url"
    echo "VERSION=$version"
    return 0
}

function install_apidog() {
    local install_dir="$1"
    local temp_file=$(mktemp)
    local current_dir=$(pwd)
    local arch=$(get_arch)
    local download_info=$(get_download_info)

    # Check for dependencies before proceeding with installation
    check_dependencies
    check_fuse || return 1

    local download_url=$(echo "$download_info" | grep "URL=" | sed 's/^URL=//')
    local version=$(echo "$download_info" | grep "VERSION=" | sed 's/^VERSION=//')

    echo "Downloading Apidog..."
    if ! curl -L "$download_url" -o "$temp_file"; then
        echo "Failed to download Apidog" >&2
        rm -f "$temp_file"
        return 1
    fi

    # Extract the ZIP file
    echo "Extracting Apidog from ZIP..."
    local temp_extract_dir=$(mktemp -d)
    if ! unzip -q "$temp_file" -d "$temp_extract_dir"; then
        echo "Failed to extract Apidog ZIP file" >&2
        rm -f "$temp_file"
        rm -rf "$temp_extract_dir"
        return 1
    fi

    # Find the AppImage in the extracted files
    local appimage_file=$(find "$temp_extract_dir" -name "*.AppImage" -type f | head -n 1)
    if [ -z "$appimage_file" ]; then
        echo "No AppImage found in the downloaded ZIP file" >&2
        rm -f "$temp_file"
        rm -rf "$temp_extract_dir"
        return 1
    fi

    # Move the AppImage to the install directory
    chmod +x "$appimage_file"
    mv "$appimage_file" "$install_dir/apidog.appimage"
    
    # Clean up temporary files
    rm -f "$temp_file"
    rm -rf "$temp_extract_dir"

    # Ensure execution permissions persist post-move
    chmod +x "$install_dir/apidog.appimage"
    if [ -x "$install_dir/apidog.appimage" ]; then
        echo "Execution permissions confirmed for $install_dir/apidog.appimage"
    else
        echo "Warning: Failed to set execution permissions—check filesystem." >&2
        return 1
    fi

    # Verify binary architecture matches host
    local binary_info=$(file "$install_dir/apidog.appimage" 2>/dev/null || echo "unreadable")
    local expected_grep="x86-64"
    if [ "$arch" = "arm64" ]; then
        expected_grep="ARM aarch64"
    fi
    if ! echo "$binary_info" | grep -q "$expected_grep"; then
        echo "Error: Arch mismatch detected ($binary_info). Expected $expected_grep. Aborting install." >&2
        rm -f "$install_dir/apidog.appimage"
        return 1
    fi
    echo "Binary verified: $binary_info"

    # Store version information in a simple file
    echo "$version" >"$install_dir/.apidog_version"

    echo "Extracting icons and desktop file..."
    local temp_extract_dir=$(mktemp -d)
    cd "$temp_extract_dir"

    # Extract icons
    if ! "$install_dir/apidog.appimage" --appimage-extract "usr/share/icons" >/dev/null 2>&1; then
        echo "Warning: Icon extraction failed—skipping." >&2
    fi
    # Extract desktop file
    if ! "$install_dir/apidog.appimage" --appimage-extract "apidog.desktop" >/dev/null 2>&1; then
        echo "Warning: Desktop extraction failed—skipping." >&2
    fi

    # Verify extraction succeeded before copying
    if [ ! -d "squashfs-root" ]; then
        echo "Error: Extraction failed (squashfs-root missing). Check arch/FUSE." >&2
        cd "$current_dir"
        rm -rf "$temp_extract_dir"
        return 1
    fi

    # Copy icons
    local icon_dir="$HOME/.local/share/icons/hicolor"
    mkdir -p "$icon_dir"
    if [ -d "squashfs-root/usr/share/icons/hicolor" ]; then
        cp -r squashfs-root/usr/share/icons/hicolor/* "$icon_dir/" 2>/dev/null || echo "Warning: Icon copy failed."
    fi

    # Copy desktop file
    local apps_dir="$HOME/.local/share/applications"
    mkdir -p "$apps_dir"
    if [ -f "squashfs-root/apidog.desktop" ]; then
        cp squashfs-root/apidog.desktop "$apps_dir/"
        # Update desktop file to point to the correct AppImage location
        sed -i "s|Exec=.*|Exec=$install_dir/apidog.appimage --no-sandbox|g" "$apps_dir/apidog.desktop"

        # Fix potential icon name mismatch in the extracted desktop file
        sed -i 's/^Icon=.*/Icon=apidog/' "$apps_dir/apidog.desktop"

        # Refresh desktop database for menu visibility
        update-desktop-database "$apps_dir" 2>/dev/null || true
        echo ".desktop file installed and updated."
    else
        echo "Warning: apidog.desktop not found in extraction—manual setup needed."
    fi

    # Clean up
    cd "$current_dir"
    rm -rf "$temp_extract_dir"

    echo "Apidog has been installed to $install_dir/apidog.appimage"
    echo "Icons and desktop file have been extracted and placed in the appropriate directories"
}

function update_apidog() {
    echo "Updating Apidog..."
    local current_appimage=$(find_apidog_appimage)
    local install_dir

    if [ -n "$current_appimage" ]; then
        install_dir=$(dirname "$current_appimage")
    else
        install_dir=$(get_install_dir)
    fi

    install_apidog "$install_dir"
}

function launch_apidog() {
    local apidog_appimage=$(find_apidog_appimage)

    if [ -z "$apidog_appimage" ]; then
        echo "Error: Apidog AppImage not found. Running update to install it."
        update_apidog
        apidog_appimage=$(find_apidog_appimage)
    fi

    # Pre-launch safeguard (re-chmod + arch check)
    if [ ! -x "$apidog_appimage" ]; then
        echo "Fixing execution permissions..."
        chmod +x "$apidog_appimage"
    fi
    local binary_info=$(file "$apidog_appimage" 2>/dev/null || echo "unreadable")
    if ! echo "$binary_info" | grep -q "$(get_arch | sed 's/x64/x86-64/;s/arm64/ARM aarch64/')"; then
        echo "Error: Arch mismatch in binary ($binary_info). Re-update." >&2
        return 1
    fi

    # Create a log file to capture output and errors
    local log_file="/tmp/apidog_appimage.log"

    # Set environment variable to disable GPU if needed
    export APIDOG_DISABLE_GPU='true'

    # Run the AppImage in the background using nohup, redirecting output and errors to a log file
    nohup "$apidog_appimage" --no-sandbox "$@" >"$log_file" 2>&1 &

    # Capture the process ID (PID) of the background process
    local pid=$!

    # Wait briefly (1 second) to allow the process to start
    sleep 1

    # Check if the process is still running
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "Error: Apidog AppImage failed to start. Check the log for details."
        cat "$log_file"
    else
        echo "Apidog AppImage is running."
    fi
}

function get_version() {
    local apidog_appimage=$(find_apidog_appimage)
    if [ -z "$apidog_appimage" ]; then
        echo "Apidog is not installed"
        return 1
    fi

    local install_dir=$(dirname "$apidog_appimage")
    local version_file="$install_dir/.apidog_version"

    if [ -f "$version_file" ]; then
        local version=$(cat "$version_file")
        if [ -n "$version" ]; then
            echo "Apidog version: $version"
            return 0
        else
            echo "Version information is empty"
            return 1
        fi
    else
        echo "Version information not available"
        return 1
    fi
}

# Parse command-line arguments
if [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
    get_version
    exit $?
elif [ "$1" == "--update" ]; then
    update_apidog
elif [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: apidog [--update | --version]"
    echo "  --update: Update Apidog to the latest version"
    echo "  --version, -v: Show the installed version of Apidog"
    exit 0
else
    launch_apidog "$@"
fi

exit $?

