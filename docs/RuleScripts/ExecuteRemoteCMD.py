# sudo apt-get install python3-pip
# pip install paramiko

import paramiko
import time

REMOTE_HOST="100.69.177.11"
USERNAME="administrator"
PASSWORD="!!123abc"
PRIVATE_KEY="./wansimkey"

COMMANDS = ['pwd', 'ls -l','./iperf3Test.sh 100.71.0.244']

# Source and destination paths for SCP
local_path = 'path_to_local_file'
remote_path = 'path_to_remote_directory'

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

# Use SCP to upload a local file to the remote host
sftp = ssh_client.open_sftp()
sftp.put(local_path, remote_path)
sftp.close()

# Use SCP to download a remote file to the local host
# sftp.get(remote_path, local_path)


# Close the SSH connection. Need more time to close, so use sleep to avoid exceptions.
time.sleep(5)
ssh.close()