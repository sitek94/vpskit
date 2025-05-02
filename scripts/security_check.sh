#!/bin/bash
# Security check
# Check if core security essentials are installed and enabled
# - fail2ban
# - ufw
# - sshd hardening

set -e

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31m🚨 Run this script as root or with sudo! 🚨\033[0m"
    exit 1
fi

# fail2ban
systemctl is-active --quiet fail2ban && echo "✅ fail2ban: OK" || echo "❌ fail2ban: NOT RUNNING"

# ufw
ufw status | grep -q "Status: active" && echo "✅ UFW: OK" || echo "❌ UFW: NOT ENABLED"

# sshd hardening
sshd_config="/etc/ssh/sshd_config"
grep -q "^PasswordAuthentication no" $sshd_config && echo "✅ SSH: PasswordAuthentication disabled" || echo "❌ SSH: PasswordAuthentication ENABLED"
grep -q "^PermitRootLogin no" $sshd_config && echo "✅ SSH: Root login disabled" || echo "❌ SSH: Root login ENABLED"

echo "🎉 Security check complete! 🎉"