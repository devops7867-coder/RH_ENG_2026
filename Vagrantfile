# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # ==========================================================
  # BASE BOX
  # ==========================================================
  # This must match the local box name shown by:
  #   vagrant box list
  #
  # Expected:
  #   rhel96-vanilla (virtualbox, 0, amd64)
  #
  config.vm.box = "rhel96-vanilla"

  # Keep Vagrant using the known insecure key.
  # Your base image should already contain the Vagrant insecure public key.
  config.ssh.insert_key = false

  # Disable shared folder to avoid Guest Additions issues.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # ==========================================================
  # GLOBAL VIRTUALBOX SETTINGS
  # ==========================================================
  # Each VM gets:
  #   RAM: 1536 MB
  #   CPU: 1
  #   Disk: inherited from the rhel96-vanilla base box.
  #
  # Your screenshot shows the cloned controller disk is 20 GB,
  # so each clone should inherit 20 GB from the base image.
  #
  config.vm.provider "virtualbox" do |vb|
    vb.memory = 1536
    vb.cpus = 1
    vb.linked_clone = true
  end

  # ==========================================================
  # COMMON PROVISIONING FOR ALL MACHINES
  # ==========================================================
  config.vm.provision "shell", inline: <<-SHELL
    set -e

    echo "=========================================================="
    echo "Starting common RHCE lab provisioning on $(hostname)"
    echo "=========================================================="

    # --------------------------------------------------------
    # Base packages
    # --------------------------------------------------------
    sudo dnf -y install openssh-server sudo firewalld NetworkManager policycoreutils-python-utils vim-enhanced bash-completion || true

    sudo systemctl enable --now sshd
    sudo systemctl enable --now firewalld
    sudo systemctl enable --now NetworkManager

    # --------------------------------------------------------
    # Regenerate SSH host keys if missing
    # --------------------------------------------------------
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
      sudo ssh-keygen -A
      sudo systemctl restart sshd || true
    fi

    # --------------------------------------------------------
    # /etc/hosts for the full RHCE lab
    # --------------------------------------------------------
    sudo sed -i '/# --- RHCE LAB HOSTS START ---/,/# --- RHCE LAB HOSTS END ---/d' /etc/hosts

    cat <<'EOF' | sudo tee -a /etc/hosts >/dev/null
# --- RHCE LAB HOSTS START ---
192.168.56.10 controller.example.com controller
192.168.56.20 reposerver.example.com reposerver
192.168.56.11 servera.example.com servera
192.168.56.12 serverb.example.com serverb
192.168.56.13 serverc.example.com serverc
192.168.56.14 serverd.example.com serverd
192.168.56.15 servere.example.com servere
# --- RHCE LAB HOSTS END ---
EOF

    # --------------------------------------------------------
    # Create Ansible automation user
    # --------------------------------------------------------
    if ! id ansi_user >/dev/null 2>&1; then
      sudo useradd -m -s /bin/bash ansi_user
    fi

    echo "ansi_user:redhat" | sudo chpasswd
    sudo usermod -aG wheel ansi_user

    cat <<'EOF' | sudo tee /etc/sudoers.d/90-ansi_user >/dev/null
ansi_user ALL=(ALL) NOPASSWD:ALL
EOF

    sudo chmod 440 /etc/sudoers.d/90-ansi_user
    sudo visudo -cf /etc/sudoers.d/90-ansi_user

    # --------------------------------------------------------
    # Create test user with no SSH access
    # --------------------------------------------------------
    if ! id test_user >/dev/null 2>&1; then
      sudo useradd -m -s /bin/bash test_user
    fi

    echo "test_user:redhat" | sudo chpasswd

    # test_user is intentionally NOT given sudo access.
    # test_user is also blocked from SSH below.

    # --------------------------------------------------------
    # SSH policy
    # ansi_user: SSH allowed
    # test_user: SSH denied
    # root: SSH denied
    # --------------------------------------------------------
    sudo mkdir -p /etc/ssh/sshd_config.d

    cat <<'EOF' | sudo tee /etc/ssh/sshd_config.d/99-rhce-lab.conf >/dev/null
PubkeyAuthentication yes
PasswordAuthentication yes
PermitRootLogin no
UseDNS no
GSSAPIAuthentication no
DenyUsers test_user
EOF

    sudo systemctl restart sshd

    # --------------------------------------------------------
    # SELinux
    # Keep enforcing for RHCE practice.
    # --------------------------------------------------------
    sudo setenforce 1 || true
    sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config || true

    echo "Common provisioning complete on $(hostname)"
  SHELL

  # ==========================================================
  # CONTROLLER
  # ==========================================================
  config.vm.define "controller" do |controller|
    controller.vm.hostname = "controller.example.com"
    controller.vm.network "private_network", ip: "192.168.56.10"

    controller.vm.provider "virtualbox" do |vb|
      vb.name = "RHCE_controller"
      vb.memory = 1536
      vb.cpus = 1
    end

    controller.vm.provision "shell", inline: <<-SHELL
      set -e

      echo "=========================================================="
      echo "Configuring Ansible controller"
      echo "=========================================================="

      sudo dnf -y install ansible-core git sshpass vim-enhanced bash-completion tree rsync || true

      sudo -u ansi_user mkdir -p /home/ansi_user/.ssh
      sudo chmod 700 /home/ansi_user/.ssh

      if [ ! -f /home/ansi_user/.ssh/id_ed25519 ]; then
        sudo -u ansi_user ssh-keygen -t ed25519 -N "" -f /home/ansi_user/.ssh/id_ed25519 -C "ansi_user@controller"
      fi

      cat <<'EOF' | sudo tee /home/ansi_user/ansible.cfg >/dev/null
[defaults]
inventory = /home/ansi_user/inventory.ini
remote_user = ansi_user
private_key_file = /home/ansi_user/.ssh/id_ed25519
host_key_checking = False
become = True
interpreter_python = auto_silent

[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
EOF

      cat <<'EOF' | sudo tee /home/ansi_user/inventory.ini >/dev/null
[controller]
controller.example.com ansible_host=192.168.56.10

[repo]
reposerver.example.com ansible_host=192.168.56.20

[nodes]
servera.example.com ansible_host=192.168.56.11
serverb.example.com ansible_host=192.168.56.12
serverc.example.com ansible_host=192.168.56.13
serverd.example.com ansible_host=192.168.56.14
servere.example.com ansible_host=192.168.56.15

[all_servers:children]
repo
nodes

[all:vars]
ansible_user=ansi_user
ansible_become=yes
EOF

      sudo chown -R ansi_user:ansi_user /home/ansi_user/.ssh /home/ansi_user/ansible.cfg /home/ansi_user/inventory.ini

      # Helper command to copy SSH keys from controller to all lab machines.
      cat <<'EOF' | sudo tee /usr/local/sbin/rhce-copy-ssh-keys >/dev/null
#!/usr/bin/env bash
set -euo pipefail

PASSWORD="${1:-redhat}"

for host in reposerver servera serverb serverc serverd servere; do
  echo "Copying SSH key to ${host}..."
  sshpass -p "${PASSWORD}" ssh-copy-id \
    -o StrictHostKeyChecking=accept-new \
    -i /home/ansi_user/.ssh/id_ed25519.pub \
    ansi_user@"${host}"
done

echo "Testing Ansible connectivity..."
sudo -iu ansi_user ansible all -m ping
EOF

      sudo chmod 755 /usr/local/sbin/rhce-copy-ssh-keys

      echo "Controller setup complete."
      echo "After all VMs are up, run:"
      echo "  sudo rhce-copy-ssh-keys redhat"
      echo "  sudo -iu ansi_user"
      echo "  ansible all -m ping"
    SHELL
  end

  # ==========================================================
  # REPOSITORY SERVER
  # ==========================================================
  config.vm.define "reposerver" do |repo|
    repo.vm.hostname = "reposerver.example.com"
    repo.vm.network "private_network", ip: "192.168.56.20"

    repo.vm.provider "virtualbox" do |vb|
      vb.name = "RHCE_reposerver"
      vb.memory = 1536
      vb.cpus = 1
    end

    repo.vm.provision "shell", inline: <<-SHELL
      set -e

      echo "=========================================================="
      echo "Configuring repository server"
      echo "=========================================================="

      sudo dnf -y install httpd createrepo_c dnf-utils yum-utils || true

      sudo mkdir -p /var/www/html/lab_repo/BaseOS
      sudo mkdir -p /var/www/html/lab_repo/AppStream

      # Try to download a few useful packages if active repos are available.
      # This will not break provisioning if Red Hat repos are unavailable.
      sudo dnf download --downloadonly --destdir=/var/www/html/lab_repo/BaseOS tmux || true
      sudo dnf download --downloadonly --destdir=/var/www/html/lab_repo/AppStream mariadb-server || true

      sudo createrepo_c /var/www/html/lab_repo/BaseOS || true
      sudo createrepo_c /var/www/html/lab_repo/AppStream || true

      sudo systemctl enable --now httpd

      sudo firewall-cmd --permanent --add-service=http || true
      sudo firewall-cmd --reload || true

      sudo restorecon -Rv /var/www/html || true

      cat <<'EOF' | sudo tee /etc/yum.repos.d/rhce-lab.repo >/dev/null
[lab-baseos]
name=RHCE Lab BaseOS
baseurl=http://reposerver/lab_repo/BaseOS/
enabled=0
gpgcheck=0

[lab-appstream]
name=RHCE Lab AppStream
baseurl=http://reposerver/lab_repo/AppStream/
enabled=0
gpgcheck=0
EOF

      sudo dnf clean all || true

      echo "Repository server setup complete."
      echo "BaseOS:    http://reposerver/lab_repo/BaseOS/"
      echo "AppStream: http://reposerver/lab_repo/AppStream/"
    SHELL
  end

  # ==========================================================
  # MANAGED NODES
  # ==========================================================
  servers = {
    "servera" => "192.168.56.11",
    "serverb" => "192.168.56.12",
    "serverc" => "192.168.56.13",
    "serverd" => "192.168.56.14",
    "servere" => "192.168.56.15"
  }

  servers.each do |name, ip|
    config.vm.define name do |node|
      node.vm.hostname = "#{name}.example.com"
      node.vm.network "private_network", ip: ip

      node.vm.provider "virtualbox" do |vb|
        vb.name = "RHCE_#{name}"
        vb.memory = 1536
        vb.cpus = 1
      end

      node.vm.provision "shell", inline: <<-SHELL
        set -e

        echo "=========================================================="
        echo "Configuring managed node: #{name}"
        echo "=========================================================="

        sudo dnf -y install vim-enhanced bash-completion tar gzip rsync chrony firewalld || true

        sudo systemctl enable --now chronyd || true
        sudo systemctl enable --now firewalld || true

        cat <<'EOF' | sudo tee /etc/yum.repos.d/rhce-lab.repo >/dev/null
[lab-baseos]
name=RHCE Lab BaseOS
baseurl=http://reposerver/lab_repo/BaseOS/
enabled=0
gpgcheck=0

[lab-appstream]
name=RHCE Lab AppStream
baseurl=http://reposerver/lab_repo/AppStream/
enabled=0
gpgcheck=0
EOF

        sudo dnf clean all || true

        echo "#{name} managed node setup complete."
      SHELL
    end
  end

end
