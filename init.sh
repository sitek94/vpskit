#!/bin/bash
# Initialize the VPS Kit

if ! command -v dpkg &> /dev/null; then
    echo "Are you sure this is Ubuntu/Debian?"
    exit 1
fi

if ! command -v git &> /dev/null; then
    echo "Git not found. Installing..."
    apt update && apt install -y git
fi

cd /opt/ || exit 1

# Remove old vps-kit if exists
if [ -d /opt/vps-kit ]; then
    rm -rf /opt/vps-kit
fi

git clone https://github.com/sitek94/vps-kit

echo "Done - check /opt/vps-kit for your scripts."
