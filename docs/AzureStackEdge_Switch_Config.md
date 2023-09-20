# Azure Stack Network Switch Configuration
![Sample Diagram](../img/wansim-lab-diagram00.png)
## Configuration
Please check [AzureStack_Network_Switch_Config_Generator](https://github.com/microsoft/AzureStack_Network_Switch_Config_Generator), which can generate both Switch and WAN-SIM VM configuration with input template JSON automatically.

Here are sample network switch configuration: [TOR1](../config/azurestackswitch_tor1.config) and [TOR2](../config/azurestackswitch_tor2.config)

## Design
The key parts for this design are:
- Switches select GRE tunnel as default route.
- If GRE tunnel down or WAN-SIM down, switches back to standard traffic path.
- Optimize the subnets routing to avoid routing loop.
### BGP Peer with Uplink Router
- Advertise all network except default route learnt from WAN-SIM
- Receive only default route and loopback subnet
    - Border default route as backup route. default local-preference 100.
    - Loopback subnet to establish GRE tunnel.

### BGP Peer with WAN-SIM
- BGP update source using GRE Tunnel
- Set local-preference higher than uplink router to be the best route.
- No routes should be sent to WAN-SIM to avoid routing loop.

## Post-Validation
### Ping
Ping remote host or public dns.
```
AS1-TOR1# ping 172.16.0.11 source-interface vlan 7 count 5
PING 172.16.0.11 (172.16.0.11): 56 data bytes
64 bytes from 172.16.0.11: icmp_seq=0 ttl=60 time=4.274 ms
64 bytes from 172.16.0.11: icmp_seq=1 ttl=60 time=3.72 ms
64 bytes from 172.16.0.11: icmp_seq=2 ttl=60 time=5.041 ms
64 bytes from 172.16.0.11: icmp_seq=3 ttl=60 time=3.257 ms
64 bytes from 172.16.0.11: icmp_seq=4 ttl=60 time=3.455 ms

--- 172.16.0.11 ping statistics ---
5 packets transmitted, 5 packets received, 0.00% packet loss
round-trip min/avg/max = 3.257/3.949/5.041 ms

AS1-TOR1# ping 172.16.0.11 source-interface vlan 8 count 5
PING 172.16.0.11 (172.16.0.11): 56 data bytes
64 bytes from 172.16.0.11: icmp_seq=0 ttl=60 time=4.474 ms
64 bytes from 172.16.0.11: icmp_seq=1 ttl=60 time=3.792 ms
64 bytes from 172.16.0.11: icmp_seq=2 ttl=60 time=5.134 ms
64 bytes from 172.16.0.11: icmp_seq=3 ttl=60 time=3.893 ms
64 bytes from 172.16.0.11: icmp_seq=4 ttl=60 time=3.639 ms

--- 172.16.0.11 ping statistics ---
5 packets transmitted, 5 packets received, 0.00% packet loss
round-trip min/avg/max = 3.639/4.186/5.134 ms
```
### Traceroute
Traceroute remote host or public dns to see if the traffic is being redirected.
```
AS1-TOR1# traceroute 172.16.0.11 source-interface vlan 7
traceroute to 172.16.0.11 (172.16.0.11) from 100.73.7.2 (100.73.7.2), 30 hops max, 40 byte packets
 1  20.0.0.2 (20.0.0.2) (AS 65003)  3.342 ms  2.782 ms  2.485 ms
 2  10.0.0.9 (10.0.0.9) (AS 65003)  2.843 ms  3.058 ms  2.888 ms
 3  172.16.0.11 (172.16.0.11) (AS 65003)  3.281 ms  3.584 ms  3.143 ms
AS1-TOR1# traceroute 172.16.0.11 source-interface vlan 8
traceroute to 172.16.0.11 (172.16.0.11) from 100.73.8.2 (100.73.8.2), 30 hops max, 40 byte packets
 1  20.0.0.2 (20.0.0.2) (AS 65003)  4.405 ms  4.471 ms  5.608 ms
 2  10.0.0.9 (10.0.0.9) (AS 65003)  4.088 ms  3.391 ms  3.037 ms
 3  172.16.0.11 (172.16.0.11) (AS 65003)  3.299 ms  6.652 ms  3.839 ms
```
### Show Command
Check BGP and interface status.
```
AS1-TOR1# show ip bgp summary 
BGP summary information for VRF default, address family IPv4 Unicast
BGP router identifier 2.2.2.2, local AS number 65002
BGP table version is 103, IPv4 Unicast config peers 3, capable peers 3
7 network entries and 13 paths using 2428 bytes of memory
BGP attribute entries [7/1204], BGP AS path entries [3/22]
BGP community entries [0/0], BGP clusterlist entries [0/0]

Neighbor        V    AS MsgRcvd MsgSent   TblVer  InQ OutQ Up/Down  State/PfxRcd
10.0.0.1        4 65001     208     301      103    0    0 00:49:21 2         
20.0.0.0        4 65003      37      51      103    0    0 00:05:02 1         
100.73.100.2    4 65002     165      57      103    0    0 00:29:16 6  

AS1-TOR1# show ip bgp neighbors 20.0.0.0 routes 
   Network            Next Hop            Metric     LocPrf     Weight Path
*>e0.0.0.0/0          20.0.0.0                          200          0 65003 i

AS1-TOR1# show ip bgp neighbors 20.0.0.0 advertised-routes 
   Network            Next Hop            Metric     LocPrf     Weight Path

AS1-TOR1# show ip bgp neighbors 10.0.0.1 routes 
   Network            Next Hop            Metric     LocPrf     Weight Path
* e0.0.0.0/0          10.0.0.1                                       0 65001 i
*>e11.11.11.11/32     10.0.0.1                                       0 65001 65003 i

AS1-TOR1# show ip bgp neighbors 10.0.0.1 advertised-routes 
   Network            Next Hop            Metric     LocPrf     Weight Path
*>l2.2.2.2/32         0.0.0.0                           100      32768 i
*>i3.3.3.3/32         100.73.100.2                      100          0 i
*>l100.73.7.0/24      0.0.0.0                           100      32768 i
*>l100.73.8.0/24      0.0.0.0                           100      32768 i
*>l100.73.125.0/26    0.0.0.0                           100      32768 i

AS1-TOR1# show ip int brief 
IP Interface Status for VRF "default"(1)
Interface            IP Address      Interface Status
Vlan7                100.73.7.2      protocol-up/link-up/admin-up       
Vlan8                100.73.8.2      protocol-up/link-up/admin-up       
Vlan125              100.73.125.2    protocol-up/link-up/admin-up       
Lo0                  2.2.2.2         protocol-up/link-up/admin-up       
Po50                 100.73.100.1    protocol-up/link-up/admin-up       
Tunnel1              20.0.0.1        protocol-up/link-up/admin-up       
Eth1/1               10.0.0.2        protocol-up/link-up/admin-up  

AS1-TOR1# show ip route 0.0.0.0
0.0.0.0/0, ubest/mbest: 1/0
    *via 20.0.0.0, [20/0], 00:15:14, bgp-65002, external, tag 65003
```