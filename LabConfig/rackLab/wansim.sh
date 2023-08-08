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

# Config eth0
sudo ifconfig eth0 100.71.60.125 netmask 255.255.255.192

# Config GRE
sudo ip tunnel add gre1 mode gre remote 100.71.85.123 local 100.66.76.31 ttl 255
sudo ip addr add 192.168.30.2/30 dev gre1
sudo ip link set gre1 up
# sudo ip tunnel del gre1
# GRE
sudo ip link set eth0 txqueuelen 10000
sudo ip link set eth0 mtu 9216
sudo ip link set gre1 mtu 9192
sudo ip link set gre1 txqueuelen 10000

## Docker Pull
### Host VM - if http 408 error
sudo ifconfig eth0 mtu 1400



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
 neighbor 100.71.60.24 description TOR1
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


# Apply Rules
## On Interface gre1
sudo tc qdisc add dev gre1 root netem rate 100mbit
sudo tc qdisc show dev gre1
sudo tc qdisc del dev gre1 root

sudo scp test00.txt administrator@100.71.55.119:/home/administrator/Downloads/

# TOR BGP Config
router bgp 65231
  router-id 100.71.60.24
  bestpath as-path multipath-relax
  log-neighbor-changes
  address-family ipv4 unicast
    network 100.69.132.0/24
    network 100.71.60.0/30
    network 100.71.60.8/30
    network 100.71.60.16/30
    network 100.71.60.24/32
    network 100.71.60.28/30
    network 100.71.60.32/30
    network 100.73.0.0/25
    maximum-paths 8
    maximum-paths ibgp 8
  template peer AZS-HLH-DVM00-65101
    remote-as 65101
    update-source loopback0
    ebgp-multihop 3
    address-family ipv4 unicast
      prefix-list DefaultRoute out
      maximum-prefix 12000 warning-only
  template peer BMC-65231
    remote-as 65231
    password 3 d112734b97ca44a7625dd021801c77d3
    address-family ipv4 unicast
      maximum-prefix 12000 warning-only
  template peer Border1-64846
    remote-as 64846
    address-family ipv4 unicast
      maximum-prefix 12000 warning-only
  template peer Border2-64846
    remote-as 64846
    address-family ipv4 unicast
      maximum-prefix 12000 warning-only
  template peer Rack01-CL01-SU01-65101
    remote-as 65101
    update-source loopback0
    ebgp-multihop 3
    address-family ipv4 unicast
      prefix-list DefaultRoute out
      maximum-prefix 12000 warning-only
  template peer iBGPPeer-65231
    remote-as 65231
    password 3 d112734b97ca44a7625dd021801c77d3
    address-family ipv4 unicast
      maximum-prefix 12000 warning-only
  neighbor 100.71.60.1
    inherit peer Border1-64846
    description 64846:P2P_Rack00/B1_To_Rack01/Tor1:100.71.60.1
    address-family ipv4 unicast
      prefix-list ExternalPrefix in
      prefix-list ExternalPrefix out
  neighbor 100.71.60.9
    inherit peer Border2-64846
    description 64846:P2P_Rack00/B2_To_Rack01/Tor1:100.71.60.9
    address-family ipv4 unicast
      prefix-list ExternalPrefix in
      prefix-list ExternalPrefix out
  neighbor 100.71.60.18
    inherit peer BMC-65231
    description 65231:P2P_Rack01/Tor1_To_Rack01/BMC:100.71.60.18
  neighbor 100.71.60.30
    inherit peer iBGPPeer-65231
    description 65231:P2P_Rack01/TOR1-ibgp-1_To_Rack01/TOR2-ibgp-1:100.71.60.30
  neighbor 100.71.60.34
    inherit peer iBGPPeer-65231
    description 65231:P2P_Rack01/TOR1-ibgp-2_To_Rack01/TOR2-ibgp-2:100.71.60.34
  neighbor 100.69.132.0/24
    inherit peer Rack01-CL01-SU01-65101
    description 65101:Rack01-CL01-SU01-Infrastructure:100.69.132.0
  neighbor 100.71.60.118/32
    inherit peer AZS-HLH-DVM00-65101
  neighbor 100.71.60.125
    inherit peer AZS-HLH-DVM00-65101
    description WAN-SIM
