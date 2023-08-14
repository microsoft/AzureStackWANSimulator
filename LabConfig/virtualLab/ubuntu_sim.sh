# !!!Not Testing
# Init
sudo apt-get update
sudo apt-get install -y net-tools frr iperf3 traceroute
NEW_HOSTNAME="WAN-SIM"
sudo hostnamectl set-hostname $NEW_HOSTNAME
sudo reboot


#Config loopback 1
sudo ip link add lo1 type dummy
sudo ip addr add 11.11.11.11/32 dev lo1
sudo ip link set lo1 up
# sudo ip link add lo2 type dummy
# sudo ip addr add 22.22.22.22/32 dev lo2
# sudo ip link set lo2 up
# Config Interface
sudo ifconfig ens3 10.0.0.10 netmask 255.255.255.252


---
## Config FRR
sudo vi /etc/frr/daemons # Enable BGP
sudo service frr start
sudo service frr restart
## Config BGP
sudo vtysh
conf t
ip forwarding
ip route 100.73.7.0/25 20.0.0.0
router bgp 65003
 bgp router-id 11.11.11.11
 no bgp ebgp-requires-policy # Disable BGP Policy
 no bgp network import-check # Disable BGP Policy
 neighbor 10.0.0.9 remote-as 65001
 !
 address-family ipv4 unicast
  network 11.11.11.11/32
  redistribute static
 exit-address-family
exit

# Config GRE
## Use HSRP IP as source, Switch need to config 100.71.125.1 instead of vlan125 to consistent
sudo ip tunnel add gre1 mode gre remote 100.71.125.1 local 11.11.11.11 ttl 255
sudo ip addr add 20.0.0.1/29 dev gre1
sudo ip link set gre1 up
# sudo ip tunnel del gre1
## Source physical interface
sudo ip tunnel add gre1 mode gre remote 100.71.125.2 local 11.11.11.11 ttl 255
sudo ip addr add 20.0.0.1/30 dev gre1
sudo ip link set gre1 up

sudo ip tunnel add gre2 mode gre remote 100.71.125.3 local 22.22.22.22 ttl 255
sudo ip addr add 20.0.0.5/30 dev gre2
sudo ip link set gre2 up
# sudo ip tunnel del gre2


# Config Static Route
# sudo ip route add 100.73.7.0/25 via 20.0.0.0
# sudo ip route add 100.73.7.0/25 via 20.0.0.2 metric 100
# sudo ip route add 100.73.7.128/25 via 20.0.0.0
# sudo ip route add 100.73.7.128/25 via 20.0.0.2 metric 100
# sudo ip route del 7.7.7.0/25 dev gre1
# sudo ip route del 7.7.7.128/25 dev gre1

# netem
# https://srtlab.github.io/srt-cookbook/how-to-articles/using-netem-to-emulate-networks.html
# Delay + Random
sudo tc qdisc add dev ens3 root netem delay 100ms 50ms 30%
# Loss
sudo tc qdisc add dev ens3 root netem loss 10%
# BW
sudo tc qdisc add dev ens3 root netem rate 500kbit
# Delay + Loss
sudo tc qdisc add dev ens3 root netem delay 100ms 50ms 30% loss 10%
# Delay + Loss + BW limitation
sudo tc qdisc add dev ens3 root netem delay 100ms 50ms 30% loss 10% rate 500kbit
## View Current Config
sudo tc qdisc show dev ens3
## Remove All
sudo tc qdisc del dev ens3 root
