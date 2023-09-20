# WAN-SIM VM Setup

![Sample Diagram](../img/wansim-lab-diagram00.png)

## Initial Bootup
Install essential packages and set hostname.

```bash
sudo apt-get update
sudo apt-get install -y net-tools frr iperf iperf3 traceroute lldpd
HOSTNAME="WAN-SIM"
sudo hostnamectl set-hostname $HOSTNAME
```

## Network Setup
Config WAN-SIM VM network interfaces.

#### Loopback Interface
- Add ip under defaul lo as GRE tunnel Source IP
- This ip will be advertised for GRE tunnel establish

#### Physical Interface
- This ip only use for establishing BGP peer with uplink router to advertise more granular routes

#### GRE Tunnel Interface
- GRE tunnel ips are private ip and can be reused
- Source IP is loopback ip
- Destination IP would be rack BMC IP. (Destination IP has to be VLAN IP not VIP, otherwise the GRE Tunnel only establish with active switch)

```bash
# Config Interface
sudo cp ./30_netplan_wansim.yaml /etc/netplan/30_netplan_wansim.yaml
sudo netplan apply
```
Here is an example for [netplan yaml file](../config/30_netplan_wansim.yaml)

## FRR Config
- After install frr package, BGP need to be enabled in the [daemons](../config/wansim_daemons)

- Config WAN-SIM routing, check [sample frr configuration](../config/wansim_config00.config)

- WAN-SIM VM has two BGP peers.

### 1. BGP Peer with Uplink Router
#### Design
The main purposes are:
- Advertise Loopback IP 
- Let uplink router select WAN-SIM as best next hop for cluster subnets.
#### Key Points
- Advertise Loopback IP so remote TOR switches can establish the GRE Tunnel.
- Define static routes for granular subnets and advertise these static routes.
    - Uplink router will select WAN-SIM as best route because the longest mask match.
    - Example: If remote TOR switches advertise 2 * `\24` subnets, WAN-SIM will config 4 * `\25` subnets to LAN and be the best next hop.
- It is also good to use route-map to receive only default route from uplink router for clean routing table which easier for future troubleshooting.

### 2. BGP Peer with TOR Switches
#### Design
The main purpose is to let TOR switches always select GRE tunnel as default route. Only if the GRE tunnel down or the WAN-SIM is destroyed or unreachable, the TOR switches will automatically switch back to standard traffic path. So BGP is still best choice because:
- Path selection attribute based on reachability.
- Open standard support by network vendors, so won't limited by vendor technology like `ip sla`.

#### Key Points
- Use GRE tunnel IP as BGP peer IP.
- Advertise only default route to remote TOR switches.
- No routes should receive from remote TOR switches.

## Post-Validation
After WAN-SIM boot up, it is necessary to validate the status.
### Ping
If the GRE tunnel ip can be ping, 99% the solution already setup properly.
```
cisco@wansim:~$ ping 20.0.0.1 -c 5
PING 20.0.0.1 (20.0.0.1) 56(84) bytes of data.
64 bytes from 20.0.0.1: icmp_seq=1 ttl=255 time=2.15 ms
64 bytes from 20.0.0.1: icmp_seq=2 ttl=255 time=1.92 ms
64 bytes from 20.0.0.1: icmp_seq=3 ttl=255 time=1.92 ms
64 bytes from 20.0.0.1: icmp_seq=4 ttl=255 time=2.16 ms
64 bytes from 20.0.0.1: icmp_seq=5 ttl=255 time=2.23 ms

--- 20.0.0.1 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4007ms
rtt min/avg/max/mdev = 1.919/2.076/2.225/0.129 ms
cisco@wansim:~$ ping 20.0.0.3 -c 5
PING 20.0.0.3 (20.0.0.3) 56(84) bytes of data.
64 bytes from 20.0.0.3: icmp_seq=1 ttl=255 time=2.86 ms
\64 bytes from 20.0.0.3: icmp_seq=2 ttl=255 time=2.85 ms
64 bytes from 20.0.0.3: icmp_seq=3 ttl=255 time=3.03 ms
64 bytes from 20.0.0.3: icmp_seq=4 ttl=255 time=2.52 ms
64 bytes from 20.0.0.3: icmp_seq=5 ttl=255 time=3.01 ms

--- 20.0.0.3 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 4005ms
rtt min/avg/max/mdev = 2.524/2.855/3.032/0.181 ms
```
### Show Commands
Sample from virtual lab.
```
cisco@wansim:~$ sudo service frr start
cisco@wansim:~$ sudo vtysh
WAN-SIM# show ip bgp summary 
Neighbor        V         AS MsgRcvd MsgSent   TblVer  InQ OutQ  Up/Down State/PfxRcd
10.0.0.9        4      65001      29      26        0    0    0 00:02:30            1
20.0.0.1        4      65002       6       6        0    0    0 00:02:24            0
20.0.0.3        4      65002       6       6        0    0    0 00:02:23            0
Total number of neighbors 3

WAN-SIM# show ip bgp neighbors 20.0.0.1 routes 
WAN-SIM# 

WAN-SIM# show ip bgp neighbors 20.0.0.1 advertised-routes 
Originating default network 0.0.0.0/0

WAN-SIM# show ip bgp neighbors 20.0.0.3 routes 
WAN-SIM# 

WAN-SIM# show ip bgp neighbors 20.0.0.3 advertised-routes 
Originating default network 0.0.0.0/0

WAN-SIM# show ip bgp neighbors 10.0.0.9 routes 
   Network          Next Hop            Metric LocPrf Weight Path
*> 0.0.0.0/0        10.0.0.9                               0 65001 i

WAN-SIM# show ip bgp neighbors 10.0.0.9 advertised-routes 
   Network          Next Hop            Metric LocPrf Weight Path
*> 0.0.0.0/0        10.0.0.9                               0 65001 i
*> 11.11.11.11/32   0.0.0.0                  0         32768 i
*> 100.73.7.0/25    0.0.0.0                  0         32768 ?
*> 100.73.7.128/25    0.0.0.0                  0         32768 ?
*> 100.73.8.0/25    0.0.0.0                  0         32768 ?
*> 100.73.8.128/25    0.0.0.0                  0         32768 ?
Total number of prefixes 4
```

## Q&A
### Does WAN-SIM VM has to be stay in the same data center of Azure Stack Cluster?
In therory, no, because unless the GRE tunnels  and BGP can be established, the WAN-SIM solution can be applied. However, to have better network profile rule control, it would be good to install in the same location with Azure Stack Cluster.

### Is there any automation to generate these configuration?
Yes, please check [AzureStack_Network_Switch_Config_Generator](https://github.com/microsoft/AzureStack_Network_Switch_Config_Generator), which can generate both Switch and WAN-SIM VM configuration with input template JSON.