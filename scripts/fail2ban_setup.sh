#!/bin/bash
# fail2ban setup
# One-shot setup for fail2ban with SSH, nginx-badbots, and nginx-attacks jails (Ubuntu only)

set -e

if [[ $EUID -ne 0 ]]; then
    echo -e "\033[1;31mRun this script as root or with sudo!\033[0m"
    exit 1
fi

# Prompt for SSH port with default 22
read -p "Set SSH port (e.g. on Mikrus VPS it's 10332) [22]: " SSH_PORT
SSH_PORT=${SSH_PORT:-22}

# Install fail2ban
apt update
apt install -y fail2ban

# Stop fail2ban before config
systemctl stop fail2ban || true

# Overwrite jail.local
cat > /etc/fail2ban/jail.local <<EOF
[nginx-badbots]
enabled = true
port = http,https
filter = nginx-badbots
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 31536000
findtime = 86400

[nginx-attacks]
enabled = true
port = http,https
filter = nginx-attacks
logpath = /var/log/nginx/access.log
maxretry = 2
bantime = 31536000
findtime = 86400

[sshd]
enabled = true
port = $SSH_PORT
bantime = 31536000
findtime = 86400
maxretry = 3
mode = aggressive
EOF

# Create nginx-badbots filter if missing
if [ ! -f /etc/fail2ban/filter.d/nginx-badbots.conf ]; then
cat > /etc/fail2ban/filter.d/nginx-badbots.conf <<EOF
[Definition]
failregex = ^<HOST> -.*"(GET|POST|HEAD).*HTTP.*"(?:%(badbots)s)"$
ignoreregex =
EOF
fi

# Create nginx-attacks filter
cat > /etc/fail2ban/filter.d/nginx-attacks.conf <<EOF
[INCLUDES]
before = common.conf

[Definition]
failregex = ^<HOST> -.*"(GET|POST).*.php.*" 404
            ^<HOST> -.*"(GET|POST).*\.env.*" 404
            ^<HOST> -.*"(GET|POST).*parameters\.yml.*" 404
            ^<HOST> -.*"(GET|POST).*phpunit.*eval-stdin\.php.*" 404
            ^<HOST> -.*"(GET|POST).*/think.*call_user_func_array.*" 404
            ^<HOST> -.*"(GET|POST).*\.git/config.*" 404
            ^<HOST> -.*"(GET|POST).*phpinfo.*" 200
            ^<HOST> -.*"(GET|POST).*/server-status.*" 404
            ^<HOST> -.*"(GET|POST).*/config\.json.*" 404
            ^<HOST> -.*"(GET|POST).*/telescope/.*" 404
            ^<HOST> -.*"(GET|POST).*cgi-bin/.*" 404
            ^<HOST> -.*"(GET|POST).*\.aws/credentials.*" 404
            ^<HOST> -.*"(GET|POST).*\.env\..*" 404
            ^<HOST> -.*"(GET|POST).*\.config\.yaml.*" 404
            ^<HOST> -.*"(GET|POST).*application/.*" 404
            ^<HOST> -.*"(GET|POST).*/favicon\.ico.*" 404
            ^<HOST> -.*"(GET|POST).*/wp-admin.*" 404
            ^<HOST> -.*"(GET|POST).*/wp-login.*" 404
            ^<HOST> -.*"(GET|POST).*\.sql.*" 404
            ^<HOST> -.*"(GET|POST).*/administrator.*" 404
            ^<HOST> -.*"(GET|POST).*/jenkins.*" 404
            ^<HOST> -.*"(GET|POST).*\.htaccess.*" 404
            ^<HOST> -.*"(GET|POST).*/solr/.*" 404
            ^<HOST> -.*"(GET|POST).*/api/swagger.*" 404
            ^<HOST> -.*"(GET|POST).*/api/docs.*" 404

ignoreregex =
EOF

# Enable and start fail2ban
systemctl enable --now fail2ban

# Show status
systemctl status fail2ban --no-pager
fail2ban-client status

echo -e "\n\033[1;32mFail2ban setup complete!\033[0m"
echo "Check jails with: fail2ban-client status"
echo "Check banned IPs: fail2ban-client status sshd | grep Banned"
echo "Check banned IPs: fail2ban-client status nginx-badbots | grep Banned"
echo "Check banned IPs: fail2ban-client status nginx-attacks | grep Banned"
