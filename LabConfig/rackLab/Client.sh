iperf -c 192.168.1.100 -B 192.168.2.50

# Generate dumy file with specify size. 
## 1G 1000*1M
dd if=/dev/zero of=test1G.txt bs=1M count=1000
## 100M 100*1M
dd if=/dev/zero of=test100M.txt bs=1M count=100
## 1G 1000*10M
dd if=/dev/zero of=test10G.txt bs=10M count=1000

# scp /path/to/local/file username@remote_ip:/path/to/destination/
sudo scp test100M.txt administrator@100.69.177.11:/home/administrator/Downloads/
sudo scp test1G.txt administrator@100.69.177.11:/home/administrator/Downloads/
sudo scp test10G.txt administrator@100.69.177.11:/home/administrator/Downloads/

sudo scp test100M.txt administrator@100.71.55.119:/home/administrator/Downloads/
sudo scp test10G.txt administrator@100.71.55.119:/home/administrator/Downloads/

scp test00.txt administrator@100.69.178.11:/home/administrator/Downloads/
test00.txt                                      0% 2128KB   1.6MB/s   10:15 ETA

# WGET
## Golang
wget https://go.dev/dl/go1.21.0.darwin-amd64.tar.gz
## go1.21.0.darwin-amd 100%[===================>]  64.03M   117MB/s    in 0.5s    
## Ubuntu Server 1.5G
wget https://releases.ubuntu.com/20.04.6/ubuntu-20.04.6-live-server-amd64.iso


# Minikube