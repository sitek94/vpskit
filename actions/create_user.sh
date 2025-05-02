#!/usr/bin/env bash
# Create a new user with sudo access and copy authorized_keys

set -euo pipefail

usage() {
  echo "🚨 Usage: $0 <username> [source_user_for_keys]"
  exit 1
}

if [[ $(id -u) -ne 0 ]]; then
  echo "🚨 You must run this script as root (try: sudo $0 ...)" >&2
  exit 1
fi

username="${1:-}"  # required
source_user="${2:-$SUDO_USER}"  # optional, default: invoking user

if [[ -z "$username" ]]; then
  usage
fi

if id "$username" &>/dev/null; then
  echo "🚨 User $username already exists!"
  exit 1
fi

# Password generation (always auto-generate, no prompt)
password=$(head -c255 /dev/urandom | base64 | grep -Eoi '[a-z0-9]{12}' | head -n1)
echo "Generated password for $username: $password"

# Create user
useradd -m -p "$(openssl passwd -1 "$password")" -s /bin/bash "$username"
echo "User $username created."

# Assign groups
echo "Assigning groups..."
usermod -aG sudo "$username"
echo "sudo: ok"

if ! getent group sshusers > /dev/null; then
  groupadd sshusers
fi
usermod -aG sshusers "$username"
echo "sshusers: ok"

if ! getent group docker > /dev/null; then
  groupadd docker
fi
usermod -aG docker "$username"
echo "docker: ok"

# SSH
echo "Configuring SSH..."
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
echo "SSH: ok"

# Symlink `vpskit` to `/opt/vpskit`
if [[ -d /opt/vpskit && ! -e "/home/$username/vpskit" ]]; then
  echo "Symlinking vpskit..."
  ln -s /opt/vpskit "/home/$username/vpskit"
  chown -h "$username:$username" "/home/$username/vpskit"
  echo "vpskit: ok"
fi

echo "🎉 User $username successfully created with sudo and SSH access"

echo -e "\n\033[1;33m=============================="
echo "🚨 NEW USER CREDENTIALS 🚨"
echo "=============================="
echo "👤 Username: $username"
echo "🔑 Password: $password"
echo "=============================="
echo -e "👆 Remember to save the password in a secure location\033[0m\n"