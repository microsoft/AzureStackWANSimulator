# Init
sudo apt-get update
sudo apt-get install -y net-tools iperf3 traceroute lldpd
NEW_HOSTNAME="Client"
sudo hostnamectl set-hostname $NEW_HOSTNAME
sudo reboot

# Config Interfaces
sudo ip addr add 172.16.0.11/24 dev ens3
sudo ip link set ens3 up

# Config Default Route
sudo ip route add 0.0.0.0/0 via 172.16.0.1 dev ens3
# sudo ip route del 0.0.0.0/0 via 172.16.0.1 dev ens3

# Apply Rule
## Config
### Delay + Loss
sudo tc qdisc add dev ens3 root netem delay 100ms 50ms 30% loss 10%
sudo tc qdisc add dev ens3 root netem loss 100%
### BW Limitation
sudo tc qdisc add dev ens3 root netem rate 500kbit
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


# Generate dumy file with specify size. Below is 1G 100*10M
dd if=/dev/zero of=test00.txt bs=10M count=100

# scp /path/to/local/file username@remote_ip:/path/to/destination/
scp test00.txt cisco@100.73.7.11:/home/cisco