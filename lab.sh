#!/usr/bin/env bash
set -euo pipefail

TITLE="RHCE Dynamic Lab Environment Manager"

green="\e[32m"
red="\e[31m"
yellow="\e[33m"
reset="\e[0m"

pause() { read -rp "Press ENTER to continue..." _; }

deploy_lab_all() {
  echo -e "${green}>>> Deploying / starting ALL lab VMs with Vagrant...${reset}"
  vagrant up
  echo -e "${green}>>> Lab deployment complete.${reset}"
  pause
}

deploy_lab_custom() {
  clear
  echo -e "${yellow}Custom VM deployment${reset}"
  echo
  echo "Defined VMs (from Vagrantfile):"
  echo "  controller reposerver servera serverb serverc serverd servere"
  echo
  read -rp "Enter VM names to start (space-separated): " vms
  [[ -z "${vms}" ]] && { echo "No VMs selected."; pause; return 0; }

  echo -e "${green}>>> Deploying selected VMs: ${vms}${reset}"
  vagrant up ${vms}
  echo -e "${green}>>> Selected VMs deployment complete.${reset}"
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
      # Ignore SSH errors on shutdown; Vagrant will still force-destroy
      vagrant destroy -f || true
      ;;
    b|B)
      echo
      echo "Existing VMs:"
      vagrant status | sed '1,2d'
      echo
      read -rp "Enter VM names to destroy (space-separated): " vms
      [[ -z "${vms}" ]] && { echo "No VMs selected."; pause; return 0; }
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
    echo "1) Deploy / Start ALL Lab VMs"
    echo "2) Deploy / Start SELECTED Lab VMs"
    echo "3) Destroy Lab Elements"
    echo "4) SSH into a VM"
    echo "5) Run lab_setup.sh on controller"
    echo "6) Exit"
    echo
    read -rp "Choose an option [1-6]: " opt
    case "$opt" in
      1) deploy_lab_all ;;
      2) deploy_lab_custom ;;
      3) destroy_lab ;;
      4) ssh_menu ;;
      5) run_lab_setup ;;
      6) exit 0 ;;
      *) echo "Invalid choice"; pause ;;
    esac
  done
}

main_menu
