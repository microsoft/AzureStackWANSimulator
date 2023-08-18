#!/bin/bash

# Generate SSH Key Pair and Pass to WAN-SIM
# So the NETEM rules can be applied from same test host without loginin WAN-SIM

# sudo apt install sshpass

# Initial Variables
remote_host="20.0.0.0"
remote_username="cisco"
remote_password="cisco"
ssh_prikey_name="~/.ssh/wansimkey"
ssh_pubkey_name="~/.ssh/wansimkey.pub"

# Generate SSH key pair
ssh-keygen -t rsa -b 2048 -f ~/.ssh/wansimkey -N ""

# Transfer public key to remote host using ssh-copy-id
ssh-copy-id -i $ssh_pubkey_name "$remote_username@$remote_host"

# SSH using private key
ssh -i $ssh_prikey_name "$remote_username@$remote_host"

ssh-copy-id -i ~/.ssh/wansimkey.pub cisco@100.73.7.11
ssh -i ~/.ssh/wansimkey cisco@100.73.7.11

# Manual Method
# cat ~/.ssh/wansimkey.pub | ssh user@hostname 'cat >> .ssh/authorized_keys'

# # Clean up generated SSH keys (optional)
# rm ~/.ssh/id_rsa
# rm ~/.ssh/id_rsa.pub

# Execute Command on Remote Host
ssh -i ~/.ssh/wansimkey cisco@100.73.7.11 'pwd'
scp -i ~/.ssh/wansimkey -r cisco@100.73.7.11:~/ProfileTestLog/ ~/ProfileTestLog/

# scp local_file.txt user@remote_host:/path/on/remote
# scp user@remote_host:/path/on/remote/remote_file.txt local_directory/
# scp -r local_directory/ user@remote_host:/path/on/remote/
