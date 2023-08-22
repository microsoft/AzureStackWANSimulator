#!/bin/bash

# Generate pre-defined profile testing results.
# 1. Define template functions
# 2. Define common profiles
# 3. Output standard result with detail log files

# Initialize Variables
logDir="ProfileTestLog"
strPingTest="PingTest"
strPerf3Test="Perf3Test"

ErrorInvalidIPv4="Invalid or missing remote host IP address."

# Validate Input IPv4 Address
function valid_ip() 
{
    # From https://www.linuxjournal.com/content/validating-ip-address-bash-script
	local  ip=$1
  local  stat=1

  if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.'
    ip=($ip)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
        && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    stat=$?
  fi
  return $stat
}

# iPerf3 Test Template
function iperf3_test() 
{
  local ThreadNum=${2:-1}
  local TestSeconds=${3:-10}
  local logFileName="$strPerf3Test-$ThreadNum.log"
  local logFilePath="./$logDir/$logFileName"

  iperf3 -c $Iperf3SvrIP -P $ThreadNum -t $TestSeconds -i 1 --logfile $logFilePath

  if [ -e "$logFilePath" ]; then
    echo "iperf3 -c $Iperf3SvrIP -P $ThreadNum -t $TestSeconds -i 1 --logfile $logFilePath" >> $logFilePath
    echo "$logFilePath Generated Successfully!"
  else
    echo "$logFilePath Fail! Please check command manually: iperf3 -c $Iperf3SvrIP -P $ThreadNum -t $TestSeconds -i 1 --logfile $logFilePath"
  fi
}

# Refresh Log Folder
if [ -d "$logDir" ]
then
  rm -f ./$logDir/*
else
  mkdir $logDir
fi

# Main
# Get iPerf3 Server IP
Iperf3SvrIP=""
if valid_ip $1
then
  Iperf3SvrIP=$1
else
  printf "$ErrorInvalidIPv4\n"
  exit 1
fi

# Customized testing or Pre-Profile Testing
if [ -z "$2" ]; then
  ## 1 thread
  iperf3_test $Iperf3SvrIP 1
  ## 4 thread
  iperf3_test $Iperf3SvrIP 4
  ## 8 thread
  iperf3_test $Iperf3SvrIP 8
  ## 16 thread
  iperf3_test $Iperf3SvrIP 16
else
  iperf3_test $Iperf3SvrIP $2 $3
fi

# iperf3 -c 172.16.0.11 -i 1 -t 3 -P 2 
# iperf3 -c 172.16.0.11 -i 1 -t 3 | grep -Po '[0-9.]*.(?:M|K|)bits\/sec'

# iperf3 -c 172.16.0.11 -P 2 -t 5 -i 1 --logfile ./ProfileTestLog/test.log

# DelayBase="100ms"
# DelayRandom="50ms"
# DelayRandomPercent="30%"
# sudo tc qdisc add dev $INTF root netem delay $DelayBase $DelayRandom $DelayRandomPercent


# sudo tc qdisc add dev eth0 root netem delay $DelayBase $DelayRandom $DelayRandomPercent

# ssh user@remote_host 'command'
