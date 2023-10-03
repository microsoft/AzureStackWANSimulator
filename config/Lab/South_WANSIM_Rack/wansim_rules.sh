## Sourth
sudo tc qdisc add dev eth0 root handle 1: htb default 10
sudo tc class add dev eth0 parent 1: classid 1:5 htb rate 1Gbit
sudo tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip src 100.69.177.11/32 flowid 1:5

# Show Rule
sudo tc -s qdisc show dev eth0
sudo tc -s class show dev eth0
sudo tc filter show dev eth0

# Clean Rule
sudo tc qdisc del dev eth0 root
sudo tc qdisc show dev eth0