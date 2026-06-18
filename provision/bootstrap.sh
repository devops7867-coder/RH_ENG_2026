#!/usr/bin/env bash
set -euo pipefail

ROLE="${1:?Usage: $0 <role> <ip>}"
IP="${2:?Usage: $0 <role> <ip>}"

DOMAIN="lab.example.com"
ANSI_USER="ansi_user"
TEST_USER="test_user"
PASS="redhat"

HOST_SHORT="${ROLE}"
HOST_FQDN="${ROLE}.${DOMAIN}"

echo "=== [${HOST_SHORT}] Base bootstrap starting ==="

hostnamectl set-hostname "${HOST_FQDN}"

# Detect main ethernet interface
IFACE=$(nmcli -t -f DEVICE,TYPE,STATE device status \
  | awk -F: '$2=="ethernet" && $3=="connected"{print $1; exit}')
if [[ -z "$IFACE" ]]; then
  IFACE=$(nmcli -t -f DEVICE,TYPE device status \
    | awk -F: '$2=="ethernet"{print $1; exit}')
fi

CIDR="24"
GW="192.168.56.1"
DNS1="1.1.1.1"
DNS2="8.8.8.8"

echo "Configuring static IP on ${IFACE} -> ${IP}/${CIDR}"

nmcli con mod "${IFACE}" ipv4.method manual \
  ipv4.addresses "${IP}/${CIDR}" \
  ipv4.gateway "${GW}" \
  ipv4.dns "${DNS1},${DNS2}" \
  ipv4.dns-search "${DOMAIN}"

nmcli con mod "${IFACE}" connection.autoconnect yes
nmcli con up "${IFACE}" || nmcli con up "${IFACE}"

echo "Installing base packages..."
dnf -y install \
  openssh-server \
  sudo \
  firewalld \
  vim-enhanced \
  bash-completion \
  tree

systemctl enable --now sshd firewalld

echo "Creating users..."
if ! id "${ANSI_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${ANSI_USER}"
fi
echo "${ANSI_USER}:${PASS}" | chpasswd
usermod -aG wheel "${ANSI_USER}"

if ! id "${TEST_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${TEST_USER}"
fi
echo "${TEST_USER}:${PASS}" | chpasswd

echo "Configuring sudoers for ${ANSI_USER}..."
cat >/etc/sudoers.d/90-${ANSI_USER} <<EOF
${ANSI_USER} ALL=(ALL) NOPASSWD:ALL
EOF
chmod 440 /etc/sudoers.d/90-${ANSI_USER}

# SSH setup for ansi_user (test_user deliberately has no keys)
install -d -m 700 -o "${ANSI_USER}" -g "${ANSI_USER}" /home/${ANSI_USER}/.ssh
touch /home/${ANSI_USER}/.ssh/authorized_keys
chown "${ANSI_USER}:${ANSI_USER}" /home/${ANSI_USER}/.ssh/authorized_keys
chmod 600 /home/${ANSI_USER}/.ssh/authorized_keys

echo "Configuring sshd..."
grep -q '^PasswordAuthentication' /etc/ssh/sshd_config \
  && sed -i 's/^PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
  || echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

grep -q '^PubkeyAuthentication' /etc/ssh/sshd_config \
  && sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config \
  || echo 'PubkeyAuthentication yes' >> /etc/ssh/sshd_config

systemctl restart sshd

echo "Configuring /etc/hosts..."
cat >/etc/hosts <<EOF
127.0.0.1   localhost localhost.localdomain
::1         localhost localhost.localdomain

192.168.56.10 controller.lab.example.com controller
192.168.56.11 reposerver.lab.example.com reposerver
192.168.56.21 servera.lab.example.com servera
192.168.56.22 serverb.lab.example.com serverb
192.168.56.23 serverc.lab.example.com serverc
192.168.56.24 serverd.lab.example.com serverd
192.168.56.25 servere.lab.example.com servere
EOF

echo "=== [${HOST_SHORT}] Base bootstrap complete ==="
