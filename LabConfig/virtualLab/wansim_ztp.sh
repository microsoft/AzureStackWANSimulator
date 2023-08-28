# Init
sudo apt-get update
sudo apt-get install -y net-tools frr iperf3 traceroute
# HOSTNAME="WAN-SIM"
# sudo hostnamectl set-hostname $HOSTNAME
# sudo reboot

# Config Interface
sudo cp ./30_netplan_init.yaml /etc/netplan/30_netplan_init.yaml
sudo netplan apply

# Config FRR
sudo cp ./wansim_daemons /etc/frr/daemons
sudo service frr restart
sudo cp ./wansim_frr.conf /etc/frr/frr.conf
sudo service frr restart

# 1. Boot up WAN-SIM and config WAN-SIM 
# 2. WAN-SIM ansible-playbook to config TOR Switches
# 3. Execute Profile Testing Procedure