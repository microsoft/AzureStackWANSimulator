from netmiko import ConnectHandler
import time

def config_switch(net_connect, config_commands):
    # Send configuration commands
    output = net_connect.send_config_set(config_commands)
    print(output)

def main():
    # Define device parameters
    cisco_switch = {
        'device_type': 'cisco_nxos',
        'ip':   '172.16.0.1',
        'username': 'cisco',
        'password': 'cisco',
    }

    # Establish a connection to the device
    net_connect = ConnectHandler(**cisco_switch)

    # Define configuration commands
    tunnel_config_commands = [
        'feature tunnel',
        'interface Tunnel1',
        'ip address 2.1.1.3/31',
        'tunnel source 100.71.85.124',
        'tunnel destination 10.10.32.129',
        'description Tunnel_To_WANSIM',
        'mtu 8000',
        'no shutdown',
        'end',
        ]
    rm_tunnel_config_commands  = [
        'no interface Tunnel1', 
        'no feature tunnel',
        ]

    # Call the function
    config_switch(net_connect, tunnel_config_commands)
    time.sleep(5)
    config_switch(net_connect, rm_tunnel_config_commands)

    # Close the connection
    net_connect.disconnect()

if __name__ == "__main__":
    main()