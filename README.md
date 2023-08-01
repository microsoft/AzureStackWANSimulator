# Azure Stack WAN Simulator Project
> This repo is current private only, and will open to public once fully reviewed.

## Project Overview

To better support different Azure Stack profile service, an automated customized traffic control validation meachinsim need to be developed and deployed to suit rapid growth product request. 

### Main Components
#### SONiC
- [Images](https://github.com/sonic-net/sonic-buildimage)
- [USER MANUAL](https://github.com/sonic-net/SONiC/blob/master/doc/SONiC-User-Manual.md)

#### Network Emulator
[Using NetEm to Emulate Networks](https://srtlab.github.io/srt-cookbook/how-to-articles/using-netem-to-emulate-networks.html#:~:text=NetEm%28Network%20Emulator%29%20is%20an%20enhancement%20of%20the%20Linux,Differentiated%20Services%20%28diffserv%29%20facilities%20in%20the%20Linux%20kernel)

#### Standard DataFlow

In standard deployment, it is hard to automate the traffic control rules in the data path.

```mermaid
flowchart LR

A[Client] <--> |Routing| B(Border-Switch)
B(Border-Switch) <--> |eBGP| C(TOR-Switch)
C(TOR-Switch) <--> |VLAN| D[VM-Host]
```

#### Customized DataFlow with WAN-SIM Setup

Add vSONiC vm to redirect routes and apply traffic control rules on tunnels to suit needs.

```mermaid
flowchart LR
A[Client] <--> |Routing| B(Border-Switch)
B(Border-Switch) <--> |eBGP| D(vSONiC)
C(TOR-Switch) <-.-> |GRE Tunnel| D(vSONiC)
C(TOR-Switch) <--> |VLAN| E[VM-Host]
```

## Contributing

This project welcomes contributions and suggestions.  Most contributions require you to agree to a
Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us
the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## Trademarks

This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft 
trademarks or logos is subject to and must follow 
[Microsoft's Trademark & Brand Guidelines](https://www.microsoft.com/en-us/legal/intellectualproperty/trademarks/usage/general).
Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship.
Any use of third-party trademarks or logos are subject to those third-party's policies.
