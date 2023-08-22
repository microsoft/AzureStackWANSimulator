#!/bin/bash

# Generate predefined profile rules and Execute with timer
# 1. Define template functions for profile rules
# 2. Define common profiles
# 3. Execute remote ASZ Host to run testing 
# 4. Remove the rules with timer

# Initialize Variables
Intf=""
RemoteTestHostIP=""
T1="1.544mbit"
E1="2.048mbit"
Broadband="25mbit"
Satellite_Download="100mbit"
Satellite_Upload="20mbit"
Satellite_Latency="50ms"
Satellite_Loss="2%"

logDir="ProfileRuleLog"

ErrorInvalidIPv4="Invalid or missing remote host IP address."

# Validate Input Interface Name
function interface_exists() {
  ifconfig "$1" >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    Intf=$1
    echo "Interface $Intf exists"
  else
    echo "Interface $1 does not exist"
    exit 1
  fi
}

# # Validate Input IPv4 Address
# function valid_ip() 
# {
#     # From https://www.linuxjournal.com/content/validating-ip-address-bash-script
# 	local  ip=$1
#   local  stat=1

#   if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
#     OIFS=$IFS
#     IFS='.'
#     ip=($ip)
#     IFS=$OIFS
#     [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
#         && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
#     stat=$?
#   fi
#   return $stat
# }

# NETEM Rule Template
function tc_rule_apply() 
{
  local BWLimit=${2}
  local Latency=${3}
  local LossRate=${4}
  local RuleSeconds=${5:-60}
  local logFileName="ProfileRule.log"
  local logFilePath="./$logDir/$logFileName"

  date | tee -a $logFilePath

  if [[ -n "$1" && -n "$2" && -z "$3" && -z "$4" ]]; then
    ## BW Limitation Rule Only
    sudo tc qdisc add dev $Intf root netem rate $BWLimit
  elif [[ -n "$1" && -n "$2" && -n "$3" && -z "$4" ]]; then
    ## BW Limitaion + Latency Rule
    sudo tc qdisc add dev $Intf root netem rate $BWLimit delay $Latency
  elif [[ -n "$1" && -n "$2" && -n "$3" && -n "$4" ]]; then
    ## BW Limitaion + Latency Rule + Loss Rule
    sudo tc qdisc add dev $Intf root netem rate $BWLimit delay $Latency loss $LossRate
  else
    sudo tc qdisc show dev $Intf | sudo tee -a $logFilePath
    history | sudo tee -a $logFilePath
    exit 1
  fi

  sudo tc qdisc show dev $Intf | tee -a $logFilePath
  sleep $RuleSeconds && sudo tc qdisc del dev $Intf root
}

# Main
# Refresh Log Folder
if [ -d "$logDir" ]
then
  rm -f ./$logDir/*
else
  mkdir $logDir
fi
# Check input interface name
interface_exists $1

# # Main
# # Get iPerf3 Server IP
# Iperf3SvrIP=""
# if valid_ip $1
# then
#   Iperf3SvrIP=$1
# else
#   printf "$ErrorInvalidIPv4\n"
#   exit 1
# fi

# Customized testing or Pre-Profile Testing
if [ -z "$2" ]; then
  ## T1 Rule
  tc_rule_apply $Intf $T1
  ## E1 Rule
  tc_rule_apply $Intf $E1
  ## Broadband Rule
  tc_rule_apply $Intf $Broadband
  ## Satellite Rule
  tc_rule_apply $Intf $Satellite_Download $Satellite_Latency $Satellite_Loss
else
  tc_rule_apply $Intf $2 $3 $4 $5
fi