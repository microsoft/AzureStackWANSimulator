#!/bin/bash

destination_ip="<destination_ip>"

for mtu_size in {1370..1400}; do
    echo "Testing MTU size: $mtu_size"
    ping -M do -s $mtu_size -c 1 $destination_ip
    echo "----------------------------------"
done


# sudo tcpdump -i ens6f0np0 -n -vvv -s 0 host 100.69.177.11 and tcp 