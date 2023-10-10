# Azure Stack WAN Simulator Project
> This repo is still in process but feel free to PR or file issues if any feedback.

## Background

To better support Azure Edge services, by having an automated customized traffic control validation mechanism and deployed to suit rapid growth product request. 

This WAN-SIM Solution will help to validate scenarios that matches customer's network (T1,E1,Satellite,etc.) by customize network traffic control variables.

#### Before WAN-SIM Solution
- Lab design is high bandwidth, low latency.
- Edge customers networks are low bandwidth, high latency, and more unstable.

![Before WAN-SIM Solution](/img/before_wansim_solution.png)

#### After WAN-SIM Solution
- Reroute cluster traffic to WAN-SIM VM, which is a ubuntu VM with FRRouting installed.
- Use NETEM to apply rules on WAN-SIM to control traffic.
- GRE Tunnel between WAN-SIM and TOR Switches.
- Less touch points and easy to integrate with CICD and telemetry.

![After WAN-SIM Solution](/img/after_wansim_solution.png)


## Quick Start
Overall, here are main steps:
1. [Setup WAN-SIM VM](./docs/WANSIM_VM_Setup.md)
2. [Update Azure Stack Edge Switch Configuration](./docs/AzureStackEdge_Switch_Config.md)
3. [Define and Validation Network Profile Rule End-to-End](./docs/Network_Profile_Definition_Validation.md)

## Reference
- [Using NetEm to Emulate Networks](https://srtlab.github.io/srt-cookbook/how-to-articles/using-netem-to-emulate-networks.html#:~:text=NetEm%28Network%20Emulator%29%20is%20an%20enhancement%20of%20the%20Linux,Differentiated%20Services%20%28diffserv%29%20facilities%20in%20the%20Linux%20kernel)
- [FRRouting](https://github.com/FRRouting/frr)
- [iPerf](https://iperf.fr/iperf-doc.php)
- [Telegraf Agent for Telemetry](https://github.com/influxdata/telegraf)
- [Azure NetworkMonitoring](https://github.com/Azure/NetworkMonitoring/blob/main/AzureCT/PerformanceTesting.md)


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
