#!/bin/bash
# Pulls the latest version of vpskit from the repository

set -e

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31mRun this script as root or with sudo!\033[0m"
    exit 1
fi

cd /opt/vpskit

git fetch origin main
git reset --hard origin/main