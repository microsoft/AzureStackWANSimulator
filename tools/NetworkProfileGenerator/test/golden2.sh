# TC Rule for Upload
sudo tc qdisc add dev eth0 root handle 1a1a: htb default 1
sudo tc class add dev eth0 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# ENV1 Network Profile
sudo tc class add dev eth0 parent 1a1a: classid 1a1a:10 htb rate 10Mbit
sudo tc filter add dev eth0 protocol ip parent 1a1a: prio 1 u32 match ip src 100.72.10.1/24 flowid 1a1a:10
sudo tc filter add dev eth0 protocol ip parent 1a1a: prio 1 u32 match ip src 100.72.11.1/24 flowid 1a1a:10
# ENV2 Network Profile
sudo tc class add dev eth0 parent 1a1a: classid 1a1a:20 htb rate 5Mbit
sudo tc filter add dev eth0 protocol ip parent 1a1a: prio 1 u32 match ip src 100.72.12.1/24 flowid 1a1a:20
sudo tc filter add dev eth0 protocol ip parent 1a1a: prio 1 u32 match ip src 100.72.13.1/24 flowid 1a1a:20
# TC Rule for Download
# TC Rule for gre1
sudo tc qdisc add dev gre1 root handle 1a1a: htb default 1
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# ENV1 Network Profile
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc qdisc add dev gre1 parent 1a1a:10 handle 10 netem delay 50ms
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.1/24 flowid 1a1a:10
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.11.1/24 flowid 1a1a:10
# ENV2 Network Profile
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:20 htb rate 5Mbit
sudo tc qdisc add dev gre1 parent 1a1a:20 handle 20 netem delay 100ms loss 1%
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.12.1/24 flowid 1a1a:20
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.13.1/24 flowid 1a1a:20
# TC Rule for gre2
sudo tc qdisc add dev gre2 root handle 1a1a: htb default 1
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# ENV1 Network Profile
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc qdisc add dev gre2 parent 1a1a:10 handle 10 netem delay 50ms
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.1/24 flowid 1a1a:10
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.11.1/24 flowid 1a1a:10
# ENV2 Network Profile
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:20 htb rate 5Mbit
sudo tc qdisc add dev gre2 parent 1a1a:20 handle 20 netem delay 100ms loss 1%
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.12.1/24 flowid 1a1a:20
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.13.1/24 flowid 1a1a:20
