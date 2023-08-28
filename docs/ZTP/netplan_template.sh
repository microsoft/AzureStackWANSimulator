network:
    version: 2
    renderer: networkd
    ethernets:
        ens2:
            dhcp4: true
            nameservers:
                addresses:
                - 10.50.10.50
                - 8.8.8.8
        ens3:
            dhcp4: false
            mtu: 9200
            addresses:
            - 10.0.0.10/30
        lo1:
            addresses: 
            - 11.11.11.11/32
            dhcp4: no

    tunnels:
        gre1:
            mode: gre
            local: 11.11.11.11
            remote: 100.71.125.2
            addresses:
            - 20.0.0.0/31
            mtu: 9000
        gre2:
            mode: gre
            local: 11.11.11.11
            remote: 100.71.125.3
            addresses:
            - 20.0.0.2/31
            mtu: 9000
