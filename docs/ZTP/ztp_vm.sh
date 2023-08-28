# WAN-SIM ZTP
# 1. Install the FRR package: sudo apt-get install frr
# 2. Replace "/etc/frr/daemons" file with right protocol enabled, like "bgpd=yes"
# 3. Create a ZTP configuration file like "ztp.conf" and place it in the `/etc/frr` directory.
# 5. Restart services: sudo systemctl restart frr
# 6 Test connections: sudo vtysh -c "show ip bgp summary", sudo vtysh -c "show ip route"


# # sudo cat /etc/frr/frr.conf
frr version 7.2.1
frr defaults traditional
hostname WAN-SIM
log syslog informational
no ipv6 forwarding
service integrated-vtysh-config
!
ip route 100.73.7.0/25 gre1
ip route 100.73.7.0/25 gre2
!
router bgp 65003
 bgp router-id 11.11.11.11
 neighbor 10.0.0.9 remote-as 65001
 !
 address-family ipv4 unicast
  network 11.11.11.11/32
  redistribute static
 exit-address-family
!
line vty
!


# Netplan
