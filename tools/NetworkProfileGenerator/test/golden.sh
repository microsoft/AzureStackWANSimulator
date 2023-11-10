# TC Rule for gre1
# Default Rule - Change bwRate Only
sudo tc qdisc add dev gre1 root handle 1a1a: htb default 1
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW + Delay
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:10 htb rate 1Gbit
sudo tc qdisc add dev gre1 parent 1a1a:10 handle 10 netem delay 10ms
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.5/32 flowid 1a1a:10
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.6/32 flowid 1a1a:10
# Rule - BW + Loss
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:20 htb rate 1Gbit
sudo tc qdisc add dev gre1 parent 1a1a:20 handle 20 netem loss 5%
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.20/32 flowid 1a1a:20
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.178.20/24 flowid 1a1a:20
# Rule - BW + Delay + Loss
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:30 htb rate 100Mbit
sudo tc qdisc add dev gre1 parent 1a1a:30 handle 30 netem delay 50ms loss 2%
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.11/32 flowid 1a1a:30
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.12/32 flowid 1a1a:30
# TC Rule for gre2
# Default Rule - Change bwRate Only
sudo tc qdisc add dev gre2 root handle 1a1a: htb default 1
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW + Delay
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:10 htb rate 1Gbit
sudo tc qdisc add dev gre2 parent 1a1a:10 handle 10 netem delay 10ms
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.5/32 flowid 1a1a:10
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.6/32 flowid 1a1a:10
# Rule - BW + Loss
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:20 htb rate 1Gbit
sudo tc qdisc add dev gre2 parent 1a1a:20 handle 20 netem loss 5%
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.20/32 flowid 1a1a:20
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.178.20/24 flowid 1a1a:20
# Rule - BW + Delay + Loss
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:30 htb rate 100Mbit
sudo tc qdisc add dev gre2 parent 1a1a:30 handle 30 netem delay 50ms loss 2%
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.11/32 flowid 1a1a:30
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.12/32 flowid 1a1a:30
