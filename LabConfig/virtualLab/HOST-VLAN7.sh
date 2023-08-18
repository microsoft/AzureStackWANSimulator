# Init
sudo apt-get update
sudo apt-get install -y net-tools iperf3 traceroute lldpd
NEW_HOSTNAME="HOST-VLAN7"
sudo hostnamectl set-hostname $NEW_HOSTNAME
sudo reboot

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


# sudo nano /etc/netplan/50-cloud-init.yaml 
network:
  version: 2
  ethernets:
    ens2:
      dhcp4: true
    ens3:
      dhcp4: false
      mtu: 9216
    ens4:
      dhcp4: false
      mtu: 9216
  bonds:
    bond0:
      dhcp4: no
      mtu: 9216
      interfaces:
        - ens3
        - ens4
      addresses:
        - 100.73.7.11/24
      parameters:
        mode: balance-alb
        mii-monitor-interval: 100
      routes:
        - to: 0.0.0.0/0
          via: 100.73.7.1

# sudo netplan apply
cat /proc/net/bonding/bond0
# https://www.ibm.com/docs/en/linux-on-systems?topic=recommendations-bonding-modes

# Config Interface
sudo ifconfig ens3 100.73.7.11 netmask 255.255.255.0

# Config Default Route
sudo ip route add 0.0.0.0/0 via 100.73.7.1 dev ens3
# sudo ip route del 0.0.0.0/0 via 100.73.7.1 dev ens3
# sudo ip route add 100.73.7.0/25 via 20.0.0.0