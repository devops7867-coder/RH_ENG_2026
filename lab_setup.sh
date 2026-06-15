#!/usr/bin/env bash
set -euo pipefail

show_menu() {
  cat <<'MENU'
RHCE RHEL 9.6 Lab

1) Start full lab: controller, reposerver, servera-servere
2) Start controller only
3) Start reposerver only
4) Start managed nodes only
5) Halt all machines
6) Destroy all machines
7) Show status
8) Copy controller SSH key to lab servers
9) Test Ansible ping from controller
q) Quit
MENU
}

while true; do
  show_menu
  read -rp 'Choose an option: ' choice
  case "$choice" in
    1) vagrant up ;;
    2) vagrant up controller ;;
    3) vagrant up reposerver ;;
    4) vagrant up servera serverb serverc serverd servere ;;
    5) vagrant halt ;;
    6) vagrant destroy -f ;;
    7) vagrant status ;;
    8) vagrant ssh controller -c 'sudo rhce-copy-ssh-keys redhat' ;;
    9) vagrant ssh controller -c 'sudo -iu ansi_user ansible all -m ping' ;;
    q|Q) exit 0 ;;
    *) echo 'Invalid option.' ;;
  esac
  echo
 done
