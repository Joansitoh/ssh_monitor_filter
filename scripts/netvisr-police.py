import re
import subprocess
import time
import configparser

# Configurations
LOG_FILE = '/var/log/netvisr/ssh_failed.log' 
JAIL_FILE = '/etc/netvisr/jail.local'
CONFIG_FILE = '/etc/netvisr/jail.conf'

config = configparser.ConfigParser()
config.read(CONFIG_FILE)

REGEX = r'(\d+\.\d+\.\d+\.\d+)'
THRESHOLD = config.getint('ssh', 'MaxThreshold')
CHECK_INTERVAL = 0.1

ip_attempts = {}

def jail_ip(ip):
    with open(JAIL_FILE, 'a') as jail:
        jail.write(f'{ip}\n')

def block_ip(ip, silent=False):
    subprocess.run(['iptables', '-A', 'INPUT', '-s', ip, '-j', 'DROP'])
    jail_ip(ip)

    print(f'[{time.ctime()}] IP Address {ip} has been blocked.')

def read_new_lines(file, last_position):
    file.seek(last_position)
    lines = file.readlines()
    return lines, file.tell()

# Block all IPs from the jail file at the start
with open(JAIL_FILE, 'r') as jail:
    for line in jail:
        ip = line.strip()  # Remove newline character
        block_ip(ip, silent=True)

last_position = 0

while True:
    with open(LOG_FILE, 'r') as log:
        lines, last_position = read_new_lines(log, last_position)
        
        for line in lines:
            match = re.search(REGEX, line)
            if match:
                ip = match.group(1)
                if ip in ip_attempts:
                    ip_attempts[ip] += 1
                else:
                    ip_attempts[ip] = 1

                if ip_attempts[ip] >= THRESHOLD:
                    block_ip(ip)
                    ip_attempts[ip] = 0

    time.sleep(CHECK_INTERVAL)