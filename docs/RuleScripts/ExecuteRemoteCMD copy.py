# sudo apt-get install python3-pip
# pip install paramiko

import paramiko
import time

REMOTE_HOST="100.73.7.11"
USERNAME="cisco"
PASSWORD="cisco"
PRIVATE_KEY="/home/cisco/.ssh/wansimkey"

COMMANDS = ['pwd', 'ls -l']

# Create an SSH client
ssh = paramiko.SSHClient()

# Automatically add the host key
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

# # Use Username Passsword
# # Connect to the remote host
# ssh.connect(REMOTE_HOST, username=USERNAME, password=PASSWORD)

# Use SSH Key
# Load the private key
private_key = paramiko.RSAKey.from_private_key_file(PRIVATE_KEY)

# Connect to the remote host using the private key
ssh.connect(REMOTE_HOST, username=USERNAME, pkey=private_key)

# Execute multiple commands on the remote host
for command in COMMANDS:
    stdin, stdout, stderr = ssh.exec_command(command)
    print(stdout.read().decode())

# Print the output of the command
print(stdout.read().decode())

# Close the SSH connection. Need more time to close, so use sleep to avoid exceptions.
time.sleep(5)
ssh.close()
