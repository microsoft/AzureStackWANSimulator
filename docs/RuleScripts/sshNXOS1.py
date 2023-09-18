# sudo apt install python3-pip
# pip install paramiko
import paramiko
from pprint import pprint


router_ip = "2.2.2.2"
router_username = "cisco"
router_password = "cisco"

ssh = paramiko.SSHClient()

def run_command_on_device(ip_address, username, password, command):
    """ Connect to a device, run a command, and return the output."""

    # Load SSH host keys.
    ssh.load_system_host_keys()
    # Add SSH host key when missing.
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    total_attempts = 3
    for attempt in range(1, total_attempts+1):
        try:
            pprint("Attempt to connect: %s" % attempt)
            # Connect to router using username/password authentication.
            ssh.connect(router_ip, 
                        username=router_username, 
                        password=router_password,
                        look_for_keys=False )
            # Run command.
            ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(command)
            # Read output from command.
            output = ssh_stdout.readlines()
            # Close connection.
            ssh.close()
            return output

        except Exception as error_message:
            pprint("Unable to connect")
            pprint(error_message)


# Run function
commands=["show ip route 0.0.0.0","show ip int brief"]
for cmd in commands:
    result = run_command_on_device(router_ip, router_username, router_password, cmd)
    pprint(result)

# # Analyze show ip route output
# # Make sure we didn't receive empty output.
# if router_output != None:
#     for line in router_output:
#         if "0.0.0.0/0" in line:
#             pprint("Found default route:")
#             pprint(line)