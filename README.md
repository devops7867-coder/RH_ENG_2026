Here is a ready‑to‑use `README.md` you can drop into your repo alongside the other files. It explains the lab, requirements, and exact commands to run from Git Bash with Vagrant, following patterns used in other Vagrant+Ansible lab projects. [github](https://github.com/goffinet/vagrant-ansible-lab)

***

```markdown
# RH_ENG_2026 – RHCE RHEL 9 Lab

This repository contains a Vagrant‑based multi‑VM lab environment for RHCE (EX294) practice on **RHEL 9** style systems.  
It spins up a controller, a repository server, and five managed nodes, and configures them for Ansible practice.

## Lab topology

All VMs are created in VirtualBox on a host‑only network (`192.168.56.0/24`):

| Role       | Hostname                        | IP address       |
|-----------|----------------------------------|------------------|
| Controller| `controller.lab.example.com`     | `192.168.56.10`  |
| Repo      | `reposerver.lab.example.com`     | `192.168.56.11`  |
| Node 1    | `servera.lab.example.com`        | `192.168.56.21`  |
| Node 2    | `serverb.lab.example.com`        | `192.168.56.22`  |
| Node 3    | `serverc.lab.example.com`        | `192.168.56.23`  |
| Node 4    | `serverd.lab.example.com`        | `192.168.56.24`  |
| Node 5    | `servere.lab.example.com`        | `192.168.56.25`  |

Every VM has two local users:

- `ansi_user` – primary automation user, password `redhat`, passwordless sudo, SSH allowed.
- `test_user` – test/local login user, password `redhat`, no SSH keys configured.

An `/etc/hosts` file is deployed to each VM so they can resolve each other by short and FQDN hostnames.

## Components

Repository layout:

- `Vagrantfile`  
  Defines all seven VMs, their hostnames, IPs, resources, and provisioning hooks.
- `lab.sh`  
  Menu‑driven wrapper around `vagrant up`, `vagrant destroy`, and `vagrant ssh`.
- `lab_setup.sh`  
  Additional setup that runs **inside the controller** to install `ansible-core` and create a lab inventory and `ansible.cfg`.
- `provision/bootstrap.sh`  
  Base provisioning script executed on **every** VM during `vagrant up` (hostname, static IP, users, sudo, sshd, `/etc/hosts`).
- `provision/controller.sh`  
  Extra provisioning executed only on the controller VM (creates Ansible folder structure and config).

## Requirements

On the **host machine** (Windows with Git Bash, Linux, or macOS):

- [VirtualBox](https://www.virtualbox.org/) installed.
- [Vagrant](https://developer.hashicorp.com/vagrant) installed.
- Git Bash or any POSIX‑style shell (for running `lab.sh`).

Vagrant downloads the base box `generic/rhel9` by default.  
If you have your own RHEL 9.6 base box, you can change the box name in the `Vagrantfile`.

## Quick start

1. Clone the repository:

   ```bash
   git clone https://github.com/<your-username>/RH_ENG_2026.git
   cd RH_ENG_2026
   ```

2. Make scripts executable (first time only):

   ```bash
   chmod +x lab.sh lab_setup.sh
   chmod +x provision/bootstrap.sh provision/controller.sh
   ```

3. Launch the lab manager:

   ```bash
   ./lab.sh
   ```

4. In the menu, choose:

   - `1) Deploy / Start Lab Elements` to run `vagrant up` and create all VMs.
   - After `vagrant up` completes, choose  
     `4) Run lab_setup.sh on controller` to install `ansible-core` and bootstrap the Ansible lab on the controller.

5. SSH into the controller from the menu:

   - `3) SSH into a VM` → type `controller`.

6. On the controller, switch to the Ansible user and test:

   ```bash
   sudo -iu ansi_user
   cd ~/lab
   ansible all -m ping
   ```

   (You may still need to distribute `ansi_user`'s SSH key to the nodes using `ssh-copy-id` or an Ansible playbook.)

Vagrant‑based labs typically use `vagrant up` for creation/provisioning and `vagrant destroy -f` for teardown, which is exactly what this wrapper script automates for you [web:39][web:58].

## Managing the lab

From the repo root:

- **Start / provision all VMs**

  ```bash
  ./lab.sh
  # option 1
  ```

- **Destroy all VMs**

  ```bash
  ./lab.sh
  # option 2 -> a) Destroy EVERYTHING
  ```

- **Destroy selected VMs only**

  ```bash
  ./lab.sh
  # option 2 -> b) Custom destruction selection
  ```

- **SSH into a specific VM**

  ```bash
  ./lab.sh
  # option 3, then enter VM name (e.g. controller, servera)
  ```

You can also use raw Vagrant commands directly (e.g. `vagrant up`, `vagrant destroy -f`, `vagrant ssh controller`) if you prefer [web:39][web:45].

## Customization

- To change IPs or hostnames, edit the `LAB_NODES` hash and `LAB_DOMAIN` in `Vagrantfile`.
- To change RAM/CPU per VM, adjust the `vb.memory` and `vb.cpus` values in `Vagrantfile`.
- To change usernames or passwords, edit `ANSI_USER`, `TEST_USER`, and `PASS` in `provision/bootstrap.sh` and `lab_setup.sh`.
- To use a different base box (e.g. your own RHEL 9.6), change `BASE_BOX` in `Vagrantfile` to your box name.

This structure mirrors other public Vagrant+Ansible labs used for RHCE‑style environments, but is tuned for your specific RHEL 9 practice topology [web:49][web:54].
```
