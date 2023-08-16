# Profile Testing


## Network Performance
This collection of PowerShell commandlets will download required files to run the Get-LinkPerformance command which runs a series of iPerf load tests and PSPing TCP pings concurrently between a local source and a remote host running iPerf3 in server mode. Six tests of increasing load are performed and results are output at the conclusion of the test.


>**Note**: This tool is not certified by Microsoft, nor is it supported by Microsoft support. Download and use at your own risk. While the author is an employee of Microsoft, this tool is provided as my best effort to provide insight into the connectivity between an on-premise network and an Azure endpoint.


## Profile Category
All the profile testing is based on [iPerf3](https://iperf.fr/) and [NETEM](https://srtlab.github.io/srt-cookbook/how-to-articles/using-netem-to-emulate-networks.html#:~:text=NetEm%28Network%20Emulator%29%20is%20an%20enhancement%20of%20the%20Linux,Differentiated%20Services%20%28diffserv%29%20facilities%20in%20the%20Linux%20kernel).

### Template
#### NETEM Rule
- Delay rule
```bash
DelayBase="100ms"
DelayRandom="50ms"
DelayRandomPercent="30%"
sudo tc qdisc add dev $INTF root netem delay $DelayBase $DelayRandom $DelayRandomPercent
```
- Loss rule
```bash
LossPercent="10%"
sudo tc qdisc add dev $INTF root netem loss $LossPercent
```
- Bandwidth limitation rule
```bash
BWCap="500mbit"
sudo tc qdisc add dev $INTF root netem rate $BWCap
```
#### iPerf Script
```bash
ThreadNum=8
iperf3 -c $Iperf3SvrIP -t $TestSeconds -i 0 -P $ThreadNum --logfile ./$logDir/$logFile
```

### Category
No load, a PSPing TCP test without iPerf3 running, a pure TCP latency test
1 Session, a PSPing TCP test with iPerf3 running a single thread of load
6 Sessions, a PSPing TCP test with iPerf3 running a six thread load test
16 Sessions, a PSPing TCP test with iPerf3 running a 16 thread load test
16 Sessions with 1 Mb window, a PSPing TCP test with iPerf3 running a 16 thread load test with a 1 Mb window
32 Sessions, a PSPing TCP test with iPerf3 running a 32 thread load test


iperf3 -c $RemoteHost -t $TestSeconds -i 0 -P ${Threads[$i]} -w1M --logfile ./$logDir/${strTestFile[$i]}

https://github.com/Azure/NetworkMonitoring/blob/main/AzureCT/PerformanceTesting.md

https://github.com/Azure/NetworkMonitoring/blob/main/AzureCT/Linux/glp.sh