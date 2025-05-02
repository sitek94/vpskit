#!/usr/bin/env bash
# Create a new user with sudo access and copy authorized_keys

set -euo pipefail

usage() {
  echo "Usage: $0 <username> [source_user_for_keys]"
  exit 1
}

if [[ $(id -u) -ne 0 ]]; then
  echo "You must run this script as root (try: sudo $0 ...)" >&2
  exit 1
fi

username="${1:-}"  # required
source_user="${2:-$SUDO_USER}"  # optional, default: invoking user

if [[ -z "$username" ]]; then
  usage
fi

if id "$username" &>/dev/null; then
  echo "User $username already exists!"
  exit 1
fi

# Password generation (always auto-generate, no prompt)
password=$(head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1)
echo "Generated password for $username: $password"

# Create user
useradd -m -p "$(openssl passwd -1 "$password")" -s /bin/bash "$username"
echo "User $username created."

# Add to sudo group
usermod -aG sudo "$username"

# Ensure sshusers group exists
if ! getent group sshusers > /dev/null; then
  groupadd sshusers
fi

# Add user to sshusers group
usermod -aG sshusers "$username"

ssh_dir="/home/$username/.ssh"
mkdir -p "$ssh_dir"
chmod 700 "$ssh_dir"

# Copy authorized_keys
if [[ -n "$source_user" && -f "/home/$source_user/.ssh/authorized_keys" ]]; then
  cp "/home/$source_user/.ssh/authorized_keys" "$ssh_dir/authorized_keys"
else
  touch "$ssh_dir/authorized_keys"
fi
chmod 600 "$ssh_dir/authorized_keys"
chown -R "$username:$username" "$ssh_dir"

# Symlink `vps-kit` to `/opt/vps-kit`
if [[ -d /opt/vps-kit && ! -e "/home/$username/vps-kit" ]]; then
  ln -s /opt/vps-kit "/home/$username/vps-kit"
  chown -h "$username:$username" "/home/$username/vps-kit"
fi

echo "User $username successfully created with sudo and SSH access."