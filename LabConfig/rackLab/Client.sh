iperf -c 192.168.1.100 -B 192.168.2.50

# Generate dumy file with specify size. Below is 10G 1000*10M
dd if=/dev/zero of=test00.txt bs=10M count=1000

# scp /path/to/local/file username@remote_ip:/path/to/destination/
sudo scp test00.txt administrator@100.69.177.11:/home/administrator/Downloads/

sudo scp test00.txt administrator@100.66.76.31:/home/administrator/

scp test00.txt administrator@100.69.178.11:/home/administrator/Downloads/
test00.txt                                      0% 2128KB   1.6MB/s   10:15 ETA

# WGET
## go1.21.0.darwin-amd 100%[===================>]  64.03M   117MB/s    in 0.5s    
## Ubuntu Server 1.5G
wget https://releases.ubuntu.com/20.04.6/ubuntu-20.04.6-live-server-amd64.iso