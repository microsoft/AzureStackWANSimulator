#!/bin/bash

# Generate pre-defined profile testing results.
# 1. Define template functions
# 2. Define common profiles
# 3. Output standard result with detail log files

# Initialize Variables
Iperf3SvrIP=${1:-"172.16.0.11"}
logDir="WANSIMLog"
strPingTest="pingTest"
strPerf3Test="iPerf3Test"
SumLogFileName="SumResult.log"

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
  local Connections=${2:-1}
  local TestSeconds=${3:-10}
  local logFileName="$strPerf3Test-$Connections.log"
  local logFilePath="./$logDir/$logFileName"

  # Sleep 3 seconds to make sure last test finished
  sleep 3 && iperf3 -c $Iperf3SvrIP -P $Connections -t $TestSeconds -i 1 --logfile $logFilePath

  if [ -e "$logFilePath" ]; then
    echo "iperf3 -c $Iperf3SvrIP -P $Connections -t $TestSeconds -i 1 --logfile $logFilePath" >> $logFilePath
    # echo "$logFilePath Generated Successfully!"
  else
    echo "$logFilePath Fail! Please check command manually: iperf3 -c $Iperf3SvrIP -P $Connections -t $TestSeconds -i 1 --logfile $logFilePath"
  fi

  result_data=$(cat $logFilePath)
  if [[ "$result_data" =~ \[SUM\] ]]; then
    sender_line=$(echo "$result_data" | grep '\[SUM\].*sender$')
    receiver_line=$(echo "$result_data" | grep '\[SUM\].*receiver$')
  else
      sender_line=$(echo "$result_data" | grep 'sender$')
      receiver_line=$(echo "$result_data" | grep 'receiver$')
  fi

  sender_bitrate=$(echo "$sender_line" | grep -o '[0-9.]*\s*\w*bits\/sec' )
  receiver_bitrate=$(echo "$receiver_line" | grep -o '[0-9.]*\s*\w*bits\/sec' )

  printf "%-20s %-25s %-25s\n" "$Connections Connections" "Sender: $sender_bitrate" "Receiver: $receiver_bitrate"
  # printf "%-20s %-25s %-25s\n" "1 Connections" "Sender: 1.35 Mbits/sec" "Receiver: 1.35 Mbits/sec"
  # echo "$Connections Connections    Sender: $sender_bitrate   Receiver: $receiver_bitrate" | tee -a "./$logDir/$SumLogFileName"

}

# Refresh Log Folder
if [ -d "$logDir" ]
then
  rm -f ./$logDir/*
else
  mkdir $logDir
  # touch "./$logDir/$SumLogFileName"
fi

# Main
# Get iPerf3 Server IP
if valid_ip $Iperf3SvrIP
then
  Iperf3SvrIP=$Iperf3SvrIP
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

