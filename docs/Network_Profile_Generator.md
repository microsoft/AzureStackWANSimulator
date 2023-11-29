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
    "id": 10,
    "name": "Rule - BW",
    "subnets": ["100.72.10.2/23"],
    "bwRate": "50Mbit",
    "delay": "",
    "loss": ""
  }
]
```

#### Definition rules

- **DO NOT** use id `1` because its already being used as default htb id.
- Except `id:1` list item, feel free to add and delete list item with subnets.
- Update values in each list item based on needs.

| Key     | type            | Example                                 | Comment                           |
| ------- | --------------- | --------------------------------------- | --------------------------------- |
| id      | int             | 10                                      | tc class id (no overlap)          |
| name    | string          | "Profile Client1: BW10M+Delay100ms"     | profile rule comment              |
| subnets | list of strings | ["100.69.177.20/32","100.69.178.20/24"] | profile subnet list               |
| bwRate  | string          | "50Mbit"                                | Bandwidth rate (Gbit/Mbit/Kbit)   |
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
  -inboundBW string
        Total Download Bandwidth for all Subnets (default "1Gbit")
  -inboundIntfs string
        Comma-separated list of VM interfaces for inbound traffic (default "gre1,gre2")
  -input string
        Input JSON file (default "profile_input.json")
  -outboundBW string
        Total Upload Bandwidth for all Subnets (default "1Gbit")
  -outboundIntf string
        VM interfaces for outbound traffic (default "eth0")
  -output string
        Output shell script file (default "profile_rules.sh")

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
# TC Rule for Upload
sudo tc qdisc add dev eth0 root handle 1a1a: htb default 1
sudo tc class add dev eth0 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# TC Rule for Download
# TC Rule for gre1
sudo tc qdisc add dev gre1 root handle 1a1a: htb default 1
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW
sudo tc class add dev gre1 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc filter add dev gre1 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.2/23 flowid 1a1a:10
# TC Rule for gre2
sudo tc qdisc add dev gre2 root handle 1a1a: htb default 1
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:1 htb rate 1Gbit
# Rule - BW
sudo tc class add dev gre2 parent 1a1a: classid 1a1a:10 htb rate 50Mbit
sudo tc filter add dev gre2 protocol ip parent 1a1a: prio 1 u32 match ip dst 100.72.10.2/23 flowid 1a1a:10
```

Check more examples here: [Test_Cases](../tools/NetworkProfileGenerator/test/)
