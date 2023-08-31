# sudo apt install python3-pip
# pip install paramiko
import paramiko
from pprint import pprint


router_ip = "2.2.2.2"
router_username = "cisco"
router_password = "cisco"

ssh = paramiko.SSHClient()

def run_commands_on_device(ip_address, username, password, commands,outputFilename):
    """ Connect to a device, run a command, and return the output."""

    # Load SSH host keys.
    ssh.load_system_host_keys()
    # Add SSH host key when missing.
    ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    
    total_attempts = 3
    for attempt in range(1, total_attempts+1):
        try:
            print("Attempt to connect: %s" % attempt)
            # Connect to router using username/password authentication.
            ssh.connect(router_ip, 
                        username=router_username, 
                        password=router_password,
                        look_for_keys=False )
            # Run commands.
            for cmd in commands:
                ssh_stdin, ssh_stdout, ssh_stderr = ssh.exec_command(cmd)
                # Read output from command.
                output = ssh_stdout.read().decode()
                print(output)
                with open(outputFilename, 'a') as f:
                    f.write(output)

            # Close connection.
            ssh.close()
            return

        except Exception as error_message:
            print("Unable to connect")
            print(error_message)

# Run function
commands=["show ip route 0.0.0.0","show ip int brief"]
run_commands_on_device(router_ip, router_username, router_password, commands,"result.txt")

# # Analyze show ip route output
# # Make sure we didn't receive empty output.
# if router_output != None:
#     for line in router_output:
#         if "0.0.0.0/0" in line:
#             pprint("Found default route:")
#             pprint(line)