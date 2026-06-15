# -*- mode: ruby -*-
# vi: set ft=ruby :

# RHCE RHEL 9.6 VirtualBox Lab
# Machines:
#   controller  192.168.56.10
#   reposerver  192.168.56.20
#   servera     192.168.56.11
#   serverb     192.168.56.12
#   serverc     192.168.56.13
#   serverd     192.168.56.14
#   servere     192.168.56.15

ENV['RH_USER'] ||= ""
ENV['RH_PASS'] ||= ""

LAB_BOX = ENV.fetch('LAB_BOX', 'rhel96-vanilla')
LAB_DOMAIN = 'example.com'
LAB_PASSWORD = ENV.fetch('LAB_PASSWORD', 'redhat')

LAB_HOSTS = {
  'controller' => '192.168.56.10',
  'reposerver' => '192.168.56.20',
  'servera'    => '192.168.56.11',
  'serverb'    => '192.168.56.12',
  'serverc'    => '192.168.56.13',
  'serverd'    => '192.168.56.14',
  'servere'    => '192.168.56.15'
}

Vagrant.configure('2') do |config|
  config.vm.box = LAB_BOX
  config.vm.synced_folder '.', '/vagrant', disabled: true

  config.ssh.insert_key = true
  config.vm.boot_timeout = 600

  config.vm.provider 'virtualbox' do |vb|
    vb.memory = 2048
    vb.cpus = 1
    vb.linked_clone = true
  end

  config.trigger.before :destroy do |trigger|
    trigger.name = 'Unregister RHEL'
    trigger.warn = 'Attempting to unregister RHEL subscription before destroy.'
    trigger.run_remote = {
      inline: 'sudo subscription-manager unregister || true; sudo subscription-manager clean || true'
    }
  end

  common_script = <<-SHELL
    set -euo pipefail

    RH_USER="$1"
    RH_PASS="$2"
    LAB_PASSWORD="$3"

    echo 'Starting common RHCE lab provisioning...'

    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
      sudo ssh-keygen -A
    fi

    sudo systemctl enable --now sshd || true
    sudo systemctl enable --now NetworkManager || true

    if command -v subscription-manager >/dev/null 2>&1; then
      if ! sudo subscription-manager identity >/dev/null 2>&1; then
        if [ -n "$RH_USER" ] && [ -n "$RH_PASS" ]; then
          sudo subscription-manager register --username="$RH_USER" --password="$RH_PASS" --auto-attach || true
        else
          echo 'RH_USER/RH_PASS not set. Skipping Red Hat registration.'
        fi
      fi
    fi

    sudo dnf -y install openssh-server sudo firewalld NetworkManager policycoreutils-python-utils vim-enhanced bash-completion tar gzip rsync || true

    sudo systemctl enable --now sshd
    sudo systemctl enable --now firewalld
    sudo systemctl enable --now NetworkManager

    sudo sed -i '/# --- RHCE LAB HOSTS START ---/,/# --- RHCE LAB HOSTS END ---/d' /etc/hosts
    cat <<'HOSTS_EOF' | sudo tee -a /etc/hosts >/dev/null
# --- RHCE LAB HOSTS START ---
192.168.56.10 controller.example.com controller
192.168.56.20 reposerver.example.com reposerver
192.168.56.11 servera.example.com servera
192.168.56.12 serverb.example.com serverb
192.168.56.13 serverc.example.com serverc
192.168.56.14 serverd.example.com serverd
192.168.56.15 servere.example.com servere
# --- RHCE LAB HOSTS END ---
HOSTS_EOF

    if ! id ansi_user >/dev/null 2>&1; then
      sudo useradd -m -s /bin/bash ansi_user
    fi
    echo "ansi_user:${LAB_PASSWORD}" | sudo chpasswd
    sudo usermod -aG wheel ansi_user

    cat <<'SUDO_EOF' | sudo tee /etc/sudoers.d/90-ansi_user >/dev/null
ansi_user ALL=(ALL) NOPASSWD:ALL
SUDO_EOF
    sudo chmod 440 /etc/sudoers.d/90-ansi_user
    sudo visudo -cf /etc/sudoers.d/90-ansi_user

    if ! id test_user >/dev/null 2>&1; then
      sudo useradd -m -s /bin/bash test_user
    fi
    echo "test_user:${LAB_PASSWORD}" | sudo chpasswd

    cat <<'SSH_EOF' | sudo tee /etc/ssh/sshd_config.d/99-rhce-lab.conf >/dev/null
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin no
DenyUsers test_user
SSH_EOF
    sudo systemctl restart sshd

    sudo setenforce 1 || true
    sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config || true

    echo 'Common provisioning complete.'
  SHELL

  LAB_HOSTS.each do |name, ip|
    config.vm.define name do |machine|
      machine.vm.hostname = "#{name}.#{LAB_DOMAIN}"
      machine.vm.network 'private_network', ip: ip

      machine.vm.provision 'shell', args: [ENV['RH_USER'], ENV['RH_PASS'], LAB_PASSWORD], inline: common_script

      if name == 'controller'
        machine.vm.provider 'virtualbox' do |vb|
          vb.memory = 3072
          vb.cpus = 2
        end

        machine.vm.provision 'shell', path: 'scripts/controller.sh', args: [LAB_PASSWORD]
      elsif name == 'reposerver'
        machine.vm.provision 'shell', path: 'scripts/reposerver.sh'
      else
        machine.vm.provision 'shell', path: 'scripts/managed-node.sh'
      end
    end
  end
end
