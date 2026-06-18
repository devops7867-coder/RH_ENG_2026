#!/usr/bin/env bash
set -euo pipefail

ANSI_USER="ansi_user"

echo "=== [controller] controller.sh starting ==="

# Make sure ansible-core is installed
dnf -y install ansible-core git

# Create lab directory structure
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

echo "=== [controller] controller.sh complete ==="
