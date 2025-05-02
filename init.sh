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

# Optionally symlink /opt/vpskit to ~/vpskit for the current user if not already present
if [ -d /opt/vpskit ] && [ ! -e "$HOME/vpskit" ]; then
    ln -s /opt/vpskit "$HOME/vpskit"
    echo "Symlinked /opt/vpskit to $HOME/vpskit"
fi
