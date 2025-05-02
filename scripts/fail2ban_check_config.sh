#!/bin/bash
# fail2ban check config
# Script to check Fail2Ban health and config at a glance

echo "Checking Fail2Ban status..."
if systemctl is-active --quiet fail2ban; then
    echo "Fail2Ban is running."
else
    echo "Fail2Ban is not running!"
    exit 1
fi

echo -e "\nListing all active jails:"
fail2ban-client status

# Get jail list
echo -e "\nJail status summary:"
JAILS=$(fail2ban-client status | grep "Jail list" | sed -E 's/^[^:]+:[ \t]+//' | sed 's/,/ /g')
for JAIL in $JAILS; do
    echo -n "$JAIL: "
    COUNT=$(fail2ban-client get $JAIL banned 2>/dev/null | wc -w)
    echo "$COUNT IPs banned"
done

echo -e "\nRecent Fail2Ban log entries:"
LOGFILE="/var/log/fail2ban.log"
[ ! -f "$LOGFILE" ] && LOGFILE="/var/log/syslog"
grep fail2ban $LOGFILE | tail -n 10 || echo "No recent log entries found."

echo -e "\nConfiguration files location:"
echo "Main config: /etc/fail2ban/jail.conf"
echo "Local overrides: /etc/fail2ban/jail.local"
echo "Jail directory: /etc/fail2ban/jail.d/"
echo "Filter directory: /etc/fail2ban/filter.d/"
echo "Action directory: /etc/fail2ban/action.d/"

echo -e "\nTo view configuration files, use:"
echo "less /etc/fail2ban/jail.local  # If exists"
echo "ls -la /etc/fail2ban/jail.d/   # Check custom jail configurations" 