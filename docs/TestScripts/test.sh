# raw_data="[ ID] Interval           Transfer     Bitrate         Retr
# [  6]   0.00-10.00  sec  1.17 MBytes   980 Kbits/sec  332             sender
# [  6]   0.00-10.00  sec  1.09 MBytes   911 Kbits/sec                  receiver
# [  8]   0.00-10.00  sec  1.27 MBytes  1.07 Mbits/sec  372             sender
# [  8]   0.00-10.00  sec  1.21 MBytes  1.01 Mbits/sec                  receiver
# [ 10]   0.00-10.00  sec  1.41 MBytes  1.18 Mbits/sec  397             sender
# [ 10]   0.00-10.00  sec  1.31 MBytes  1.10 Mbits/sec                  receiver
# [ 12]   0.00-10.00  sec  1.29 MBytes  1.08 Mbits/sec  364             sender
# [ 12]   0.00-10.00  sec  1.23 MBytes  1.03 Mbits/sec                  receiver
# [SUM]   0.00-10.00  sec  5.14 MBytes  4.31 Mbits/sec  1465             sender
# [SUM]   0.00-10.00  sec  4.83 MBytes  4.05 Mbits/sec                  receiver"

raw_data="[  6] local 100.73.7.11 port 46432 connected to 172.16.0.11 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  6]   0.00-10.00  sec  1.87 MBytes  1.57 Mbits/sec  489   2.83 KBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  6]   0.00-10.00  sec  1.87 MBytes  1.57 Mbits/sec  489             sender
[  6]   0.00-10.00  sec  1.80 MBytes  1.51 Mbits/sec                  receiver"

# raw_data=$(cat test1.log)

if [[ "$raw_data" =~ \[SUM\] ]]; then
    sender_line=$(echo "$raw_data" | grep '\[SUM\].*sender$')
    receiver_line=$(echo "$raw_data" | grep '\[SUM\].*receiver$')
else
    sender_line=$(echo "$raw_data" | grep 'sender$')
    receiver_line=$(echo "$raw_data" | grep 'receiver$')
fi

sender_bitrate=$(echo "$sender_line" | grep -o '[0-9.]*\s*\w*bits\/sec' )
receiver_bitrate=$(echo "$receiver_line" | grep -o '[0-9.]*\s*\w*bits\/sec' )

echo "Sender Bitrate: $sender_bitrate "
echo "Receiver Bitrate: $receiver_bitrate "
