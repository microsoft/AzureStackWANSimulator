# Ubuntu 22.04
# Init
sudo apt-get update
sudo apt-get install -y net-tools frr iperf3 traceroute
NEW_HOSTNAME="WAN-SIM"
sudo hostnamectl set-hostname $NEW_HOSTNAME
sudo reboot

# Config loopback 1
sudo ip link add Loopback1 type dummy
sudo ip addr add 100.66.76.31/32 dev Loopback1
sudo ip link set Loopback1 up

sudo ip link set gre1 mtu 9076
sudo ip link set eth0 mtu 9076
sudo ip link set gre1 txqueuelen 2000

# Config GRE
sudo ip tunnel add gre1 mode gre remote 100.71.85.123 local 100.66.76.31 ttl 255
sudo ip addr add 192.168.30.2/30 dev gre1
sudo ip link set gre1 up

# IP FORWARDING !!!!
ip forwarding

hostname s46r23-ubuntu
log syslog informational
no ip forwarding
no ipv6 forwarding
service integrated-vtysh-config
!
ip route 100.69.177.0/25 192.168.30.1
!
interface Loopback1
 bandwidth 100000
exit
!
interface gre1
 bandwidth 100000
exit
!
router bgp 65101
 bgp router-id 100.66.76.31
 bgp suppress-fib-pending
 bgp log-neighbor-changes
 no bgp ebgp-requires-policy
 no bgp default ipv4-unicast
 neighbor 100.71.60.24 remote-as 65231
 neighbor 100.71.60.24 description Tor1
 neighbor 100.71.60.24 ebgp-multihop 3
 neighbor 100.71.60.24 timers connect 10
 neighbor 100.71.60.25 remote-as 65231
 neighbor 100.71.60.25 description TOR2
 neighbor 100.71.60.25 ebgp-multihop 3
 !
 address-family ipv4 unicast
  network 100.66.76.31/32
  redistribute static
  neighbor 100.71.60.24 activate
  neighbor 100.71.60.25 activate
 exit-address-family
exit
!
ip nht resolve-via-default
!
end
