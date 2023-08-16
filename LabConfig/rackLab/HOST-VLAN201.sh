# Init
sudo apt-get update
sudo apt-get install -y net-tools iperf3 traceroute ifenslave


# Enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl enable systemd-networkd
sudo systemctl status systemd-networkd

# sudo nano /etc/netplan/01-network-manager-all.yaml 
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens6f0np0:
      dhcp4: false
      mtu: 9216
    ens6f1np1:
      dhcp4: false
      mtu: 9216
  bonds:
    bond0:
      dhcp4: no
      mtu: 9216
      interfaces:
        - ens6f0np0
        - ens6f1np1
      addresses:
        - 100.69.177.11/24
      parameters:
        mode: active-backup
        # mode: balance-alb
        mii-monitor-interval: 100
      routes:
        - to: 0.0.0.0/0
          via: 100.69.177.1
      nameservers:
        addresses: [10.50.10.50, 8.8.8.8]
sudo netplan apply

cat /proc/net/bonding/bond0


# Apply Rule
## Config
### Delay + Loss
sudo tc qdisc add dev ens3 root netem delay 100ms 50ms 30% loss 10%
### BW Limitation
sudo tc qdisc add dev ens3 root netem delay 100ms loss 10% rate 500kbit
# sudo tc qdisc add dev ens3 root tbf rate 1mbit burst 1600 latency 50ms
## View
sudo tc qdisc show dev ens3
## Remove
sudo tc qdisc del dev ens3 root 

# iperf
## Server Mode
sudo iperf -s
## client test
iperf -c 100.73.7.11 -t 5 -i 1 -w 4m


scp test00.txt administrator@100.71.55.119:/home/administrator/Downloads/


# # Config Interface
# sudo ifconfig ens3 100.73.7.11 netmask 255.255.255.0

# # Config Default Route
# sudo ip route add 0.0.0.0/0 via 100.73.7.1 dev ens3
# # sudo ip route del 0.0.0.0/0 via 100.73.7.1 dev ens3
# # sudo ip route add 100.73.7.0/25 via 20.0.0.0



# sudo nano /etc/netplan/01-network-manager-all.yaml 
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    ens6f0np0:
      dhcp4: false
      addresses: [100.69.177.11/24]
      mtu: 9216
      routes:
        - to: 0.0.0.0/0
          via: 100.69.177.1
      nameservers:
        addresses: [10.50.10.50, 8.8.8.8]
sudo netplan apply