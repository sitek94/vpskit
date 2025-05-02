#!/bin/bash
# Initialize the VPS Kit

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (try: sudo $0)"
    exit 1
fi

if ! command -v dpkg &> /dev/null; then
    echo "Are you sure this is Ubuntu/Debian?"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    apt update && apt install -y git
fi

cd /opt/ || exit 1

# Remove old vpskit if exists
if [ -d /opt/vpskit ]; then
    rm -rf /opt/vpskit
fi

git clone https://github.com/sitek94/vpskit

echo "Done - check /opt/vpskit for your scripts."

# Symlink /opt/vpskit to the invoking user's home, not root
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    user_home=$(eval echo "~$SUDO_USER")

    # Check if the symlink already exists
    if [ -d /opt/vpskit ] && [ ! -e "$user_home/vpskit" ]; then
        ln -s /opt/vpskit "$user_home/vpskit"
        chown -h "$SUDO_USER":"$SUDO_USER" "$user_home/vpskit"
        echo "Symlinked /opt/vpskit to $user_home/vpskit"
    else
        echo "Symlink already exists"
    fi
fi