#! /bin/bash
# ufw (firewall) setup
# Install ufw and configure default rules

set -e

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31mRun this script as root or with sudo!\033[0m"
    exit 1
fi

echo "Installing ufw"
sudo apt install ufw

echo "Configuring default rules"
sudo ufw default deny incoming
sudo ufw default allow outgoing

echo "Allowing SSH port"
sudo ufw allow 22/tcp    # or your custom SSH port

echo "Allowing HTTP and HTTPS"
sudo ufw allow 80,443/tcp

echo "Enabling ufw"
sudo ufw enable

echo "Showing status"
sudo ufw status verbose

echo "Done"