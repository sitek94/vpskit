#!/bin/bash
# Harden SSHD: disables root login, disables password auth, restricts to `sshusers` group
# WARNING: Make sure /home/$USER/.ssh/authorized_keys exists and contains your public key before running!

set -e

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak.$(date +%s)"

# Check if the current user has a non-empty authorized_keys file
if [[ ! -s "$HOME/.ssh/authorized_keys" ]]; then
    echo "ERROR: $HOME/.ssh/authorized_keys does not exist or is empty. You will lose SSH access. Aborting."
    exit 1
fi

echo "Backing up $SSHD_CONFIG to $BACKUP"
cp "$SSHD_CONFIG" "$BACKUP"

declare -A settings=(
    [PermitRootLogin]="no"
    [PasswordAuthentication]="no"
    [PermitEmptyPasswords]="no"
    [MaxAuthTries]="3"
    [X11Forwarding]="no"
    [ChallengeResponseAuthentication]="no"
    [PubkeyAuthentication]="yes"
    [AuthorizedKeysFile]=".ssh/authorized_keys"
    [AllowGroups]="sshusers"
)

for key in "${!settings[@]}"; do
    value="${settings[$key]}"
    if grep -q "^$key" $SSHD_CONFIG; then
        sed -i "s/^$key.*/$key $value/" $SSHD_CONFIG
    else
        echo "$key $value" >> $SSHD_CONFIG
    fi
done

echo "Restarting sshd..."
systemctl restart sshd

echo "✅ SSH hardening complete."