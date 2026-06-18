#!/usr/bin/env bash
set -euo pipefail

TITLE="RHCE Dynamic Lab Environment Manager"

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
reset="\e[0m"

pause() { read -rp "Press ENTER to continue..." _; }

deploy_lab() {
  echo -e "${green}>>> Deploying / starting lab VMs with Vagrant...${reset}"
  vagrant up
  echo -e "${green}>>> Lab deployment complete.${reset}"
  pause
}

destroy_lab() {
  clear
  echo -e "${red}VM Destruction Options${reset}"
  echo
  echo -e "  a) Destroy ${red}EVERYTHING${reset} (wipe entire lab cluster)"
  echo -e "  b) Custom destruction selection (pick individual VMs)"
  echo
  read -rp "Select teardown strategy [a/b]: " choice

  case "$choice" in
    a|A)
      echo -e "${red}>>> Destroying ALL VMs...${reset}"
      vagrant destroy -f
      ;;
    b|B)
      echo
      echo "Existing VMs:"
      vagrant status | sed '1,2d'
      echo
      read -rp "Enter VM names to destroy (space-separated): " vms
      for vm in $vms; do
        echo -e "${red}>>> Destroying ${vm}...${reset}"
        vagrant destroy -f "$vm" || true
      done
      ;;
    *)
      echo "Invalid option"
      ;;
  esac
  pause
}

ssh_menu() {
  clear
  echo -e "${yellow}SSH Quick Access${reset}"
  echo
  echo "Vagrant-defined VMs (from Vagrantfile):"
  vagrant status | sed '1,2d'
  echo
  read -rp "Enter VM name to SSH into (or blank to cancel): " vm
  [[ -z "$vm" ]] && return 0
  vagrant ssh "$vm"
}

run_lab_setup() {
  echo
  echo "This will run /vagrant/lab_setup.sh inside controller as root."
  read -rp "Continue? [y/N]: " ans
  [[ "${ans,,}" != "y" ]] && return 0
  vagrant ssh controller -c "sudo /vagrant/lab_setup.sh"
  pause
}

main_menu() {
  while true; do
    clear
    echo -e "${yellow}${TITLE}${reset}"
    echo
    echo "1) Deploy / Start Lab Elements"
    echo "2) Destroy Lab Elements"
    echo "3) SSH into a VM"
    echo "4) Run lab_setup.sh on controller"
    echo "5) Exit"
    echo
    read -rp "Choose an option [1-5]: " opt
    case "$opt" in
      1) deploy_lab ;;
      2) destroy_lab ;;
      3) ssh_menu ;;
      4) run_lab_setup ;;
      5) exit 0 ;;
      *) echo "Invalid choice"; pause ;;
    esac
  done
}

main_menu
