#!/bin/bash

# Variables
SSH_FAILED_LOG="/var/log/netvisr/ssh_failed.log"

JAIL_LOG="/etc/netvisr/jail.local"
JAIL_CONF="/etc/netvisr/jail.conf"

show_ascii_art() {
    # Clear screen
    clear

    # Print ascii art
    cat << "EOF"
         --:::::::::::::::::::::::::::::::::::::::::-        
     -::::::::::::::::::::::::::::::::::::::::::::::::::     
   -::::::::::::::::::::::::::::::::::::::::::::::::::::::   
  -::::::::::::::::::::::::::::::::::::::::::::::::::::::::  
 -:::::::::::::::::::::::::::::::::::::::::::::::::::::::::- 
-:::::::::::::::::::::::::::::--:----:::::::::::::::::::::::-
-:-:::::::::::::::::::-:--::-----::--::::::::::::::::::::-:::
-----------------------+*###########*=-----------------------
--------------------+***###############=-+####*--------------
-----------------=*******#############*-+######*-------------
----------------**********############*-=######*-------------
--------------=*********+=--------=*###+--*##*+--------------      NetVisrt SSH Monitor Filters (v1.0)
-------------=********+------------=#####=----=--------------      ----------------------------
-------------*******+--------------=############-------------      
------------+******+-----------------***########+------------      This script will work together with the
------------+****=-----------------------*######*------------      NetVisr SSH Monitor to block IP addresses
-------------++--------------------------=#######------------      that have failed to authenticate. 
---------------=***=---------------------=#######------------
--------------******---------------------+######*------------      Configuration files:
-------------*******=-------------------=#######*------------      - /etc/netvisr/jail.conf
-------------********-------------------*#######=------------
-------------=********=---------------+########=-------------      
--------------=*********+=---------=*#########+--------------      Actions:
---------------=**********###***#############=---------------      [1] Install service
-----------------+********#################+-----------------      [2] Check service status
-------------------=*****###############*+-------------------      
----------------------=+#############*=----------------------
---------------------------======----------------------------
-------------------------------------------------------------
 ----------------------------------------------------------- 
  ---------------------------------------------------------  
    ------------------------------------------------------   
      --------------------------------------------------     
          -----------------------------------------=         


EOF
}

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

start_action() {
    # Clear all screen and show the logo with progress bar
}

# Install service
install_service() {
    # Move file scripts/netvisr-police.py to /usr/bin/netvisr/netvisr-police.py
    mkdir -p /usr/bin/netvisr
    cp scripts/netvisr-police.py /usr/bin/netvisr/netvisr-police.py
    chmod +x /usr/bin/netvisr/netvisr-police.py

    # Create configuration files
    mkdir -p /etc/netvisr
    cp config/jail.conf /etc/netvisr/jail.conf

    # Move the service, enable and start it
    cp scripts/netvisr-police.service /etc/systemd/system/netvisr-police.service
    systemctl daemon-reload
    systemctl enable netvisr-police
    systemctl start netvisr-police

    echo "Service installed successfully"
}

show_ascii_art

read -p "Action to perform [1] Install service [2] Check service status: " action

case $action in
    1)
        install_service
        ;;
    2)
        systemctl status netvisr-police
        ;;
    *)
        show_ascii_art
        echo "Invalid action"
        ;;
esac
