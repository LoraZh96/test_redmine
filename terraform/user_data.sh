#! /bin/bash
set -eux

# Injected by Terraform to identify instance role
SERVER_TAG="${server_tag}"

# Keep packages list fresh
sudo apt-get update -y

# Basic SSH hardening
sudo sed -i 's/^#\?Port 22/Port 4242/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?X11Forwarding yes/X11Forwarding no/g' /etc/ssh/sshd_config
sudo sed -i 's/^#\?PermitTunnel no/PermitTunnel no/g' /etc/ssh/sshd_config

if [ "$SERVER_TAG" = "BASTION" ]; then
    TARGET_USER="bastion"
else
    TARGET_USER="appadmin"
fi

# Create admin/bastion user and grant sudo
sudo useradd -m -s /bin/bash "$TARGET_USER"
echo "$TARGET_USER ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$TARGET_USER"
sudo sh -c "echo AllowUsers $TARGET_USER >> /etc/ssh/sshd_config"

# Authorize shared SSH keys
sudo mkdir -p "/home/$TARGET_USER/.ssh"
sudo chmod 700 "/home/$TARGET_USER/.ssh"

cat <<'SSHKEYS' | sudo tee "/home/$TARGET_USER/.ssh/authorized_keys" >/dev/null
%{ for key in ssh_keys ~}
${key}
%{ endfor ~}
SSHKEYS

sudo chmod 600 "/home/$TARGET_USER/.ssh/authorized_keys"
sudo chown -R "$TARGET_USER:$TARGET_USER" "/home/$TARGET_USER/.ssh"

# Apply new SSH daemon settings
sudo systemctl restart sshd

echo "User data completed at $(date)" | sudo tee -a /var/log/user-data.log
