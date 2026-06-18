#!/usr/bin/env bash
set -euo pipefail

ANSI_USER="ansi_user"
TEST_USER="test_user"
PASS="redhat"
DOMAIN="lab.example.com"

echo "=== [controller] Running lab_setup.sh ==="

# Base packages + ansible-core for RHEL 9
dnf -y install ansible-core git vim-enhanced tree bash-completion

# Ensure users exist (should already from bootstrap, but idempotent)
id "${ANSI_USER}" &>/dev/null || useradd -m -s /bin/bash "${ANSI_USER}"
echo "${ANSI_USER}:${PASS}" | chpasswd
usermod -aG wheel "${ANSI_USER}"

id "${TEST_USER}" &>/dev/null || useradd -m -s /bin/bash "${TEST_USER}"
echo "${TEST_USER}:${PASS}" | chpasswd

cat >/etc/sudoers.d/90-${ANSI_USER} <<EOF
${ANSI_USER} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/90-${ANSI_USER}

# Prepare SSH keys for ansi_user
install -d -m 700 -o "${ANSI_USER}" -g "${ANSI_USER}" /home/${ANSI_USER}/.ssh
if [[ ! -f /home/${ANSI_USER}/.ssh/id_ed25519 ]]; then
  sudo -u "${ANSI_USER}" ssh-keygen -t ed25519 -N "" -f /home/${ANSI_USER}/.ssh/id_ed25519
fi
touch /home/${ANSI_USER}/.ssh/authorized_keys
chown "${ANSI_USER}:${ANSI_USER}" /home/${ANSI_USER}/.ssh/authorized_keys
chmod 600 /home/${ANSI_USER}/.ssh/authorized_keys

# Ansible inventory & config
sudo -u "${ANSI_USER}" mkdir -p /home/${ANSI_USER}/lab/{inventory,playbooks,files}

cat >/home/${ANSI_USER}/lab/inventory/hosts.ini <<'EOF'
[controller]
controller ansible_host=192.168.56.10

[reposerver]
reposerver ansible_host=192.168.56.11

[managed]
servera ansible_host=192.168.56.21
serverb ansible_host=192.168.56.22
serverc ansible_host=192.168.56.23
serverd ansible_host=192.168.56.24
servere ansible_host=192.168.56.25
EOF

cat >/home/${ANSI_USER}/lab/ansible.cfg <<EOF
[defaults]
inventory = /home/${ANSI_USER}/lab/inventory/hosts.ini
host_key_checking = False
retry_files_enabled = False
remote_user = ${ANSI_USER}
private_key_file = /home/${ANSI_USER}/.ssh/id_ed25519
stdout_callback = yaml

[privilege_escalation]
become = True
become_method = sudo
become_ask_pass = False
EOF

chown -R "${ANSI_USER}:${ANSI_USER}" /home/${ANSI_USER}/lab

echo "=== [controller] lab_setup.sh complete. Next: copy SSH key to nodes or use Ansible to push it. ==="
