# Check Rules
sudo tc qdisc show dev eth0
sudo tc qdisc show dev gre1
sudo tc qdisc show dev gre2

sudo tc -s class show dev eth0
sudo tc -s class show dev gre1
sudo tc -s class show dev gre2

sudo tc filter show dev eth0
sudo tc filter show dev gre1
sudo tc filter show dev gre2
# Clean Rules
sudo tc qdisc del dev eth0 root
sudo tc qdisc del dev gre1 root
sudo tc qdisc del dev gre2 root