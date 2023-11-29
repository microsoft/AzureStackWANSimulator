# TC Rule for Upload
sudo tc qdisc add dev eth0 root handle 1a1a: htb default 1
sudo tc class add dev eth0 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# TC Rule for Download
# TC Rule for gre1
sudo tc qdisc add dev gre1 root handle 1a1a: htb default 1
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.2/23 flowid 1a1a:10
# TC Rule for gre2
sudo tc qdisc add dev gre2 root handle 1a1a: htb default 1
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.2/23 flowid 1a1a:10
