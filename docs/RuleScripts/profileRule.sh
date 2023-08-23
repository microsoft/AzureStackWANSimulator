#!/bin/bash

# Generate predefined profile rules and Execute with timer
# 1. Define template functions for profile rules
# 2. Define common profiles
# 3. Execute remote ASZ Host to run testing 
# 4. Remove the rules with timer

# Initialize Variables
Intf=${1:-"ens3"}
T1="1.544mbit"
E1="2.048mbit"
Broadband="25mbit"
Satellite_Download="100mbit"
Satellite_Upload="20mbit"
Satellite_Latency="50ms"
Satellite_Loss="2%"

RemoteTestHostIP="100.73.7.11"
Iperf3SvrIP="172.16.0.11"
Username="cisco"
PrivateKeyPath="/home/cisco/.ssh/wansimkey"
iperf3TestScript="./iperf3Test.sh"

logDir="wansimlog"
logFileName="wansim_result.log"
logFilePath="./$logDir/$logFileName"

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

function ssh_remote_cmd()
{
  local CMD=${1:-"pwd"}

  ssh -o StrictHostKeyChecking=no -i $PrivateKeyPath $Username@$RemoteTestHostIP "sudo chmod 777 $iperf3TestScript"
  ssh -o StrictHostKeyChecking=no -i $PrivateKeyPath $Username@$RemoteTestHostIP "sudo ./$iperf3TestScript $Iperf3SvrIP"
} 


# NETEM Rule Template
function tc_rule_apply() 
{
  local ProfileName=${1:-"ProfileName"}
  local BWLimit=${3}
  local Latency=${4}
  local LossRate=${5}
  local RuleSeconds=${6:-60}

  echo "Profile $1 - $(date)" | tee -a $logFilePath

  if [[ -n "$1" && -n "$2" && -n "$3" && -z "$4" && -z "$5" ]]; then
    ## BW Limitation Rule Only
    sudo tc qdisc add dev $Intf root netem rate $BWLimit
  elif [[ -n "$1" && -n "$2" && -n "$3" && -n "$4" && -z "$5" ]]; then
    ## BW Limitaion + Latency Rule
    sudo tc qdisc add dev $Intf root netem rate $BWLimit delay $Latency
  elif [[ -n "$1" && -n "$2" && -n "$3" && -n "$4" && -n "$5" ]]; then
    ## BW Limitaion + Latency Rule + Loss Rule
    sudo tc qdisc add dev $Intf root netem rate $BWLimit delay $Latency loss $LossRate
  else
    sudo tc qdisc show dev $Intf | sudo tee -a $logFilePath
    history | sudo tee -a $logFilePath
    exit 1
  fi

  sudo tc qdisc show dev $Intf | tee -a $logFilePath
  ssh_remote_cmd | tee -a $logFilePath
  sleep $RuleSeconds && sudo tc qdisc del dev $Intf root

  sudo scp -r -o StrictHostKeyChecking=no -i $PrivateKeyPath $Username@$RemoteTestHostIP:"./$logDir/" "./$logDir/$1/"
}

# Main
# Refresh Log Folder
if [ -d "$logDir" ]
then
  rm -rf ./$logDir/*
else
  mkdir $logDir
fi
# Check input interface name
interface_exists $Intf

# Check Test Script exisit
if test -e $iperf3TestScript; then
  echo "File exists"
else
    echo "File does not exist"
  exit 1
fi

# SCP Test Script to Remote Host
sudo scp -o StrictHostKeyChecking=no -i $PrivateKeyPath $iperf3TestScript $Username@$RemoteTestHostIP:$iperf3TestScript

# Customized testing or Pre-Profile Testing
if [ -z "$2" ]; then
  ## T1 Rule
  tc_rule_apply "T1" $Intf $T1 
  ## E1 Rule
  tc_rule_apply "E1" $Intf $E1 
  ## Broadband Rule
  tc_rule_apply "Broadband" $Intf $Broadband
  ## Satellite Rule
  tc_rule_apply "Satellite" $Intf $Satellite_Download $Satellite_Latency $Satellite_Loss
else
  tc_rule_apply $Intf $2 $3 $4 $5
fi

echo "********** WAN-SIM iPerf3 Result **********"
cat $logFilePath