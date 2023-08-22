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


# Rule per subnet
sudo tc qdisc add dev ens3 root handle 1:0 prio
sudo tc qdisc add dev ens3 parent 1:1 handle 10:0 netem loss 100%
sudo tc filter add dev ens3 protocol ip parent 1:0 prio 1 u32 match ip src 100.73.125.0/24 flowid 1:2
sudo tc filter add dev ens3 protocol ip parent 1:0 prio 2 u32 match ip src 100.73.0.0/16 flowid 1:1

# Rule last 1m, at does not have seconds option
echo "sudo tc qdisc del dev ens3 root" | at now + 1 minute
# Trick to use seconds
# sleep 10s && sudo tc qdisc del dev ens3 root
# show at tasks
atq

tc -s -d qdisc show dev ens3
tc filter show


# Appendix
#!/bin/bash

# Apply 50% packet loss to subnet A (10.0.0.0/24)
sudo tc qdisc add dev eth0 root handle 1: prio
sudo tc qdisc add dev eth0 parent 1:1 handle 10: netem loss 50% delay 0ms
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip src 10.0.0.0/24 flowid 1:1

# Apply 100ms delay to subnet B (10.0.1.0/24)
sudo tc qdisc add dev eth0 parent 1:2 handle 20: netem delay 100ms
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 match ip src 10.0.1.0/24 flowid 1:2
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 2 u32 match ip src 10.0.3.0/24 flowid 1:2

# Apply 500kbit rate limit to subnet C (10.0.2.0/24)
sudo tc qdisc add dev eth0 parent 1:3 handle 30: tbf rate 500kbit burst 1600 limit 3000
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 3 u32 match ip src 10.0.2.0/24 flowid 1:3