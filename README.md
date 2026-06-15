# RHCE RHEL 9.6 VirtualBox Lab

This repository builds a local RHCE practice lab using your own RHEL 9.6 vanilla Vagrant box.

## Lab machines

| VM | IP | Purpose |
|---|---:|---|
| controller | 192.168.56.10 | Ansible control node |
| reposerver | 192.168.56.20 | Local HTTP package repository |
| servera | 192.168.56.11 | Managed node |
| serverb | 192.168.56.12 | Managed node |
| serverc | 192.168.56.13 | Managed node |
| serverd | 192.168.56.14 | Managed node |
| servere | 192.168.56.15 | Managed node |

## Users

| User | Password | SSH access | Sudo |
|---|---|---|---|
| vagrant | vagrant | yes | passwordless |
| ansi_user | redhat | yes | passwordless |
| test_user | redhat | no | no |

`test_user` is blocked from SSH through `/etc/ssh/sshd_config.d/99-rhce-lab.conf`.

## Required local Vagrant box

This lab expects a local Vagrant box named:

```bash
rhel96-vanilla
```

Create it from your existing RHEL 9.6 VirtualBox VM:

```bash
vagrant package --base "RHEL-9.6-Vanilla" --output rhel96-vanilla.box
vagrant box add rhel96-vanilla ./rhel96-vanilla.box
```

Replace `RHEL-9.6-Vanilla` with the exact VM name from:

```bash
VBoxManage list vms
```

## Start the lab

```bash
chmod +x lab_setup.sh
./lab_setup.sh
```

Or directly:

```bash
vagrant up
```

## Copy Ansible SSH keys

After all machines are up:

```bash
vagrant ssh controller
sudo rhce-copy-ssh-keys redhat
sudo -iu ansi_user
ansible all -m ping
```

## Optional Red Hat registration

If your RHEL box needs Red Hat registration during provisioning:

```bash
export RH_USER='your-redhat-username'
export RH_PASS='your-redhat-password'
vagrant up
```

Do not commit credentials to Git.

## Optional environment variables

```bash
export LAB_BOX='rhel96-vanilla'
export LAB_PASSWORD='redhat'
```

## Repository server options

The default `reposerver` creates a small HTTP repo from downloaded RPMs when online repos are available.

For a stronger offline lab, attach the RHEL 9.6 ISO to `reposerver` and run:

```bash
sudo /vagrant/scripts/mount-rhel-iso-repo.sh /dev/sr0
```

Because synced folders are disabled by default, you may instead copy the script manually or temporarily enable synced folders in the Vagrantfile.
