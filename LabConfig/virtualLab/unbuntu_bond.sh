# sudo nano /etc/netplan/50-cloud-init.yaml 
network:
  version: 2
  ethernets:
    ens2:
      dhcp4: true
    ens3:
      dhcp4: false
    ens4:
      dhcp4: false
  bonds:
    bond0:
      dhcp4: no
      interfaces:
        - ens3
        - ens4
      addresses:
        - 100.73.7.22/24
      parameters:
        mode: balance-alb
        mii-monitor-interval: 100
      routes:
        - to: 0.0.0.0/0
          via: 100.73.7.1

# sudo netplan apply
cat /proc/net/bonding/bond0
