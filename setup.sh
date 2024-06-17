#!/bin/bash

# Variables
SSH_FAILED_LOG="/var/log/netvisr/ssh_failed.log"
JAIL_LOG="/etc/netvisr/jail.local"
JAIL_CONF="/etc/netvisr/jail.conf"

# Define colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Function to display ASCII art with optional messages
show_ascii_art() {
    clear
    echo -e "         --:::::::::::::::::::::::::::::::::::::::::-"
    echo -e "     -::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo -e "   -::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo -e "  -::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
    echo -e " -:::::::::::::::::::::::::::::::::::::::::::::::::::::::::-"
    echo -e "-:::::::::::::::::::::::::::::--:----:::::::::::::::::::::::-"
    echo -e "-:-:::::::::::::::::::-:--::-----::--::::::::::::::::::::-:::"
    echo -e "-----------------------+*###########*=-----------------------"
    echo -e "--------------------+***###############=-+####*--------------"
    echo -e "-----------------=*******#############*-+######*-------------"
    echo -e "----------------**********############*-=######*-------------"
    echo -e "${NC}--------------=*********+=--------=*###+--*##*+--------------      ${1:-}"
    echo -e "${NC}-------------=********+------------=#####=----=--------------      ${2:-}"
    echo -e "${NC}-------------*******+--------------=############-------------      ${3:-}"
    echo -e "${NC}------------+******+-----------------***########+------------      ${4:-}"
    echo -e "${NC}------------+****=-----------------------*######*------------      ${5:-}"
    echo -e "${NC}-------------++--------------------------=#######------------      ${6:-}"
    echo -e "${NC}---------------=***=---------------------=#######------------      ${7:-}"
    echo -e "${NC}--------------******---------------------+######*------------      ${8:-}"
    echo -e "${NC}-------------*******=-------------------=#######*------------      ${9:-}"
    echo -e "${NC}-------------********-------------------*#######=------------      ${10:-}"
    echo -e "${NC}-------------=********=---------------+########=-------------      ${11:-}"
    echo -e "${NC}--------------=*********+=---------=*#########+--------------      ${12:-}"
    echo -e "${NC}---------------=**********###***#############=---------------      ${13:-}"
    echo -e "${NC}-----------------+********#################+-----------------      ${14:-}"
    echo -e "${NC}-------------------=*****###############*+-------------------"
    echo -e "${NC}----------------------=+#############*=----------------------"
    echo -e "---------------------------======----------------------------"
    echo -e "-------------------------------------------------------------"
    echo -e " -----------------------------------------------------------"
    echo -e "  ---------------------------------------------------------"
    echo -e "    ------------------------------------------------------"
    echo -e "      --------------------------------------------------"
    echo -e "          -----------------------------------------="
    echo -e ""
}

# Check if the script is being run as root
if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root"
    exit 1
fi

# Function to install the service
install_service() {
    mkdir -p /usr/bin/netvisr
    cp scripts/netvisr-police.py /usr/bin/netvisr/netvisr-police.py
    chmod +x /usr/bin/netvisr/netvisr-police.py

    mkdir -p /etc/netvisr
    cp config/jail.conf /etc/netvisr/jail.conf

    pip3 install configparser

    cp scripts/netvisr-police.service /etc/systemd/system/netvisr-police.service
    systemctl daemon-reload
    systemctl enable netvisr-police
    systemctl start netvisr-police

    cp setup.sh /usr/bin/netvisr-police
    chmod +x /usr/bin/netvisr-police

    show_ascii_art "${GREEN}Service installed successfully" "" "Service started and enabled" "" "For open this menu use: netvisr-police" "" "Actions:" "[1] Uninstall service" "[2] Check service status" "[3] Exit${NC}"
    prompt
}

# Function to check if the service is installed
is_service_installed() {
    [[ -f /etc/systemd/system/netvisr-police.service ]]
}

# Function to uninstall the service
uninstall_service() {
    systemctl stop netvisr-police
    systemctl disable netvisr-police

    rm /etc/systemd/system/netvisr-police.service
    rm /etc/netvisr/jail.conf
    rm /usr/bin/netvisr/netvisr-police.py
    rm -rf /usr/bin/netvisr

    show_ascii_art "${GREEN}Service uninstalled successfully" "" "Service stopped and disabled" "" "Actions:" "[1] Install service" "[2] Check service status" "[3] Exit${NC}"
    prompt
}

# Function to check the status of the service
check_status() {
    if ! is_service_installed; then
        show_ascii_art "${RED}Service not installed" "" "Please install the service first" "" "Actions:" "[1] Install service" "[2] Check service status" "[3] Exit${NC}"
        prompt
    fi

    local running
    running=$(systemctl is-active netvisr-police)
    local ips_blocked
    ips_blocked=$(grep -v "#" "$JAIL_LOG" | wc -l)

    if [[ "$running" == "active" ]]; then
        show_ascii_art "${GREEN}Service is running" "" "IPs blocked: $ips_blocked" "" "Actions:" "[1] Uninstall service" "[2] Check service status" "[3] Exit${NC}"
    else
        show_ascii_art "${RED}Service is not running" "" "IPs blocked: $ips_blocked" "" "Actions:" "[1] Uninstall service" "[2] Check service status" "[3] Exit${NC}"
    fi
    prompt
}

# Initial ASCII art display
if is_service_installed; then
    show_ascii_art "NetVisr SSH Monitor Filters (v1.0)" "----------------------------" "" "Service is already installed" "" "Configuration files:" "- /etc/netvisr/jail.conf" "" "Actions:" "[1] Uninstall service" "[2] Check service status" "[3] Exit${NC}"
else
    show_ascii_art "NetVisr SSH Monitor Filters (v1.0)" "----------------------------" "" "Service is not installed" "" "Configuration files:" "- /etc/netvisr/jail.conf" "" "Actions:" "[1] Install service" "[2] Check service status" "[3] Exit${NC}"
fi

# Function to prompt user for action
prompt() {
    local options
    if is_service_installed; then
        options="[1] Uninstall service [2] Check service status [3] Exit"
    else
        options="[1] Install service [2] Check service status [3] Exit"
    fi

    read -p "Action to perform $options: " action

    case $action in
        1)
            if is_service_installed; then
                uninstall_service
            else
                install_service
            fi
            ;;
        2)
            check_status
            ;;
        3)
            exit 0
            ;;
        *)
            show_ascii_art "NetVisr SSH Monitor Filters (v1.0)" "----------------------------" "" "Invalid option" "" "Please select a valid option" "" "Configuration files:" "- /etc/netvisr/jail.conf" "" "Actions:" "[1] Install service" "[2] Check service status" "[3] Exit${NC}"
            prompt
            ;;
    esac
}

# Prompt the user
prompt
