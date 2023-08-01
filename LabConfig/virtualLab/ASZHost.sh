# Init
sudo apt-get update
sudo apt-get install -y net-tools iperf
NEW_HOSTNAME="ASZHost"
sudo hostnamectl set-hostname $NEW_HOSTNAME
sudo reboot

# Config Interface
sudo ifconfig ens3 100.73.7.11 netmask 255.255.255.0

# Config Default Route
sudo ip route add 0.0.0.0/0 via 100.73.7.1 dev ens3
# sudo ip route del 0.0.0.0/0 via 100.73.7.1 dev ens3
# sudo ip route add 100.73.7.0/25 via 20.0.0.0

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