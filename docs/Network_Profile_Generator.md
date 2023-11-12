# Network Profile Generator

## Background

This tool is designed to generate traffic control (tc) rule automatically based on the input. Please familiar with [Network_Profile_Definition_Validation](Network_Profile_Definition_Validation.md) before use this tool.

## Quick Start

### Download and Unzip Tool

- Download Link: [NetworkProfileGenerator.zip](https://github.com/microsoft/AzureStackWANSimulator/releases).
- Extract the zip package.

```powershell
PS C:\NetworkProfileGenerator> Get-ChildItem -Recurse

    Directory: C:\NetworkProfileGenerator

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d----          11/12/2023  9:33 AM                linux
d----          11/12/2023  9:33 AM                windows
-----          11/10/2023  5:48 PM            813 profile_input.json

    Directory: C:\NetworkProfileGenerator\linux

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-----          11/10/2023  5:48 PM        2488297 NetworkProfileGenerator

    Directory: C:\NetworkProfileGenerator\windows

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-----          11/10/2023  5:48 PM        2602496 NetworkProfileGenerator.exe
```

### Review and Update Input.json

Open [profile_input.json](../tools/NetworkProfileGenerator/profile_input.json) and update the values based on your network requirements.

```json
[
  {
    "id": 1,
    "name": "Default Rule - Change bwRate Only",
    "subnets": [],
    "bwRate": "1Gbit",
    "delay": "",
    "loss": ""
  },
  {
    "id": 10,
    "name": "Rule - BW + Delay",
    "subnets": ["100.69.176.5/32", "100.69.176.6/32"],
    "bwRate": "1Gbit",
    "delay": "10ms",
    "loss": ""
  },
  {
    "id": 20,
    "name": "Rule - BW + Loss",
    "subnets": ["100.69.177.20/32", "100.69.178.20/24"],
    "bwRate": "1Gbit",
    "delay": "",
    "loss": "5%"
  },
  {
    "id": 30,
    "name": "Rule - BW + Delay + Loss",
    "subnets": ["100.69.177.11/32", "100.69.177.12/32"],
    "bwRate": "100Mbit",
    "delay": "50ms",
    "loss": "2%"
  }
]
```

#### Definition rules

- In the json list, **DO NOT** change `id:1` list item except `bwRate` value if needed, because this is default rule which will apply on all the traffic.
- Except `id:1` list item, feel free to add and delete list item.
- Update values in each list item based on needs.

| Key     | type            | Example                                 | Comment                           |
| ------- | --------------- | --------------------------------------- | --------------------------------- |
| id      | int             | 10                                      | tc class id (please no overlap)   |
| name    | string          | "Profile Client1: BW10M+Delay100ms"     | profile rule comment              |
| subnets | list of strings | ["100.69.177.20/32","100.69.178.20/24"] | profile subnet list               |
| bwRate  | string          | "1Gbit"                                 | Bandwidth rate (Gbit/Mbit/Kbit)   |
| delay   | string          | "100ms"                                 | delay value for packet transition |
| loss    | string          | "5%"                                    | percentage of random packets loss |

### Execute the Tool

**Please use the tool based on your operating system!**

#### Test Environment

- OS: Windows
- Input.json: default profile_input.json

#### Execute Command

```powershell
PS C:\NetworkProfileGenerator> cd .\windows\
PS C:\NetworkProfileGenerator\windows> ls

    Directory: C:\NetworkProfileGenerator\windows

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-----          11/10/2023  5:48 PM        2602496 NetworkProfileGenerator.exe

PS C:\NetworkProfileGenerator\windows> .\NetworkProfileGenerator.exe -h
Usage of C:\NetworkProfileGenerator\windows\NetworkProfileGenerator.exe:
  -input string
        Input JSON file (default "profile_input.json")
  -output string
        Output shell script file (default "profile_rules.sh")
  -vmIntfs string
        Comma-separated list of VM interfaces (default "gre1,gre2")
  -direction string
        Direction of traffic (src/dst) (default "dst")

PS C:\NetworkProfileGenerator\windows> .\NetworkProfileGenerator.exe -input ..\profile_input.json
Profile Rule Created:  profile_rules.sh

PS C:\NetworkProfileGenerator\windows> ls

    Directory: C:\NetworkProfileGenerator\windows

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
-a---          11/10/2023  5:48 PM        2602496 NetworkProfileGenerator.exe
-a---          11/12/2023  1:15 PM           2658 profile_rules.sh
```

#### Check Result

Open output shell script to double check the tc rules.

```shell
# TC Rule for gre1
# Default Rule - Change bwRate Only
sudo tc qdisc add dev gre1 root handle 1a1a: htb default 1
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW + Delay
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:10 htb rate 1Gbit
sudo tc qdisc add dev gre1 parent 1a1a:10 handle 10 netem delay 10ms
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.5/32 flowid 1a1a:10
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.6/32 flowid 1a1a:10
# Rule - BW + Loss
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:20 htb rate 1Gbit
sudo tc qdisc add dev gre1 parent 1a1a:20 handle 20 netem loss 5%
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.20/32 flowid 1a1a:20
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.178.20/24 flowid 1a1a:20
# Rule - BW + Delay + Loss
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:30 htb rate 100Mbit
sudo tc qdisc add dev gre1 parent 1a1a:30 handle 30 netem delay 50ms loss 2%
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.11/32 flowid 1a1a:30
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.12/32 flowid 1a1a:30
# TC Rule for gre2
# Default Rule - Change bwRate Only
sudo tc qdisc add dev gre2 root handle 1a1a: htb default 1
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW + Delay
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:10 htb rate 1Gbit
sudo tc qdisc add dev gre2 parent 1a1a:10 handle 10 netem delay 10ms
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.5/32 flowid 1a1a:10
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.176.6/32 flowid 1a1a:10
# Rule - BW + Loss
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:20 htb rate 1Gbit
sudo tc qdisc add dev gre2 parent 1a1a:20 handle 20 netem loss 5%
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.20/32 flowid 1a1a:20
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.178.20/24 flowid 1a1a:20
# Rule - BW + Delay + Loss
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:30 htb rate 100Mbit
sudo tc qdisc add dev gre2 parent 1a1a:30 handle 30 netem delay 50ms loss 2%
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.11/32 flowid 1a1a:30
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.69.177.12/32 flowid 1a1a:30
```
