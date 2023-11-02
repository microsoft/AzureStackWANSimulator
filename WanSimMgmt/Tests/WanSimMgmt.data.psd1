@{
    ClusterGroup = @(
        @{
            Name      = "197ba855-5026-42f6-8896-e04e81ebd00e"
            OwnerNode = "USAS45R07U21"
            State     = "Online"
        },
        @{
            Name      = "USAS45R07WS01"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "USAS45R07WS02"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "Available Storage"
            OwnerNode = "USAS45R07U21"
            State     = "Offline"
        },
        @{
            Name      = "brian"
            OwnerNode = "USAS45R07U21"
            State     = "Online"
        },
        @{
            Name      = "Cloud Management"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "Cluster Group"
            OwnerNode = "USAS45R07U21"
            State     = "Online"
        },
        @{
            Name      = "SDDC Group"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "TestLinux"
            OwnerNode = @{ Name = "USAS45R07U21" }
            State     = "Online"
        },
        @{
            Name      = "TestWS22"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "TestWS22.1"
            OwnerNode = "USAS45R07U19"
            State     = "Online"
        },
        @{
            Name      = "TestWS22.2"
            OwnerNode = "USAS45R07U21"
            State     = "Online"
        }
    )
    ClusterResource = @(
        @{
            Name         = 'ASRR1S45R07CAU3'
            State        = 'Offline'
            OwnerGroup   = 'ASRR1S45R07CAU3'
            ResourceType = 'Distributed Network Name'
        },
        @{
            Name         = 'ASRR1S45R07CAU3Resource'
            State        = 'Offline'
            OwnerGroup   = 'ASRR1S45R07CAU3'
            ResourceType = 'ClusterAwareUpdatingResource'
        },
        @{
            Name         = 'Azure Stack HCI Cluster Agent'
            State        = 'Online'
            OwnerGroup   = 'Cloud Management'
            ResourceType = 'Generic Service'
        },
        @{
            Name         = 'Cloud Witness'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'Cloud Witness'
        },
        @{
            Name         = 'Cluster IP Address'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'IP Address'
        },
        @{
            Name         = 'Cluster IP Address 2001:4898:5808:ff2c::'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'IPv6 Address'
        },
        @{
            Name         = 'Cluster Name'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'Network Name'
        },
        @{
            Name         = 'Cluster Pool 1'
            State        = 'Online'
            OwnerGroup   = '197ba855-5026-42f6-8896-e04e81ebd00e'
            ResourceType = 'Storage Pool'
        },
        @{
            Name         = 'Cluster Virtual Disk (ClusterPerformanceHistory)'
            State        = 'Online'
            OwnerGroup   = 'SDDC Group'
            ResourceType = 'Physical Disk'
        },
        @{
            Name         = 'Health'
            State        = 'Online'
            OwnerGroup   = 'SDDC Group'
            ResourceType = 'Health Service'
        },
        @{
            Name         = 'SDDC Management'
            State        = 'Online'
            OwnerGroup   = 'SDDC Group'
            ResourceType = 'SDDC Management'
        },
        @{
            Name         = 'Storage Qos Resource'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'Storage QoS Policy Manager'
        },
        @{
            Name         = 'Task Scheduler'
            State        = 'Online'
            OwnerGroup   = 'Task Scheduler'
            ResourceType = 'Task Scheduler'
        },
        @{
            Name         = 'User Manager'
            State        = 'Online'
            OwnerGroup   = 'User Manager Group'
            ResourceType = 'User Manager'
        },
        @{
            Name         = 'Virtual Machine ASRR1S45R07WS01'
            State        = 'Online'
            OwnerGroup   = 'ASRR1S45R07WS01'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine ASRR1S45R07WS02'
            State        = 'Online'
            OwnerGroup   = 'ASRR1S45R07WS02'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine brian'
            State        = 'Online'
            OwnerGroup   = 'brian'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine Cluster WMI'
            State        = 'Online'
            OwnerGroup   = 'Cluster Group'
            ResourceType = 'Virtual Machine Cluster WMI'
        },
        @{
            Name         = 'Virtual Machine Configuration ASRR1S45R07WS01'
            State        = 'Online'
            OwnerGroup   = 'ASRR1S45R07WS01'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration ASRR1S45R07WS02'
            State        = 'Online'
            OwnerGroup   = 'ASRR1S45R07WS02'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration brian'
            State        = 'Online'
            OwnerGroup   = 'brian'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration TestLinux'
            State        = 'Online'
            OwnerGroup   = 'TestLinux'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration TestWS22'
            State        = 'Online'
            OwnerGroup   = 'TestWS22'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration TestWS22.1'
            State        = 'Online'
            OwnerGroup   = 'TestWS22.1'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine Configuration TestWS22.2'
            State        = 'Online'
            OwnerGroup   = 'TestWS22.2'
            ResourceType = 'Virtual Machine Configuration'
        },
        @{
            Name         = 'Virtual Machine TestLinux'
            State        = 'Online'
            OwnerGroup   = 'TestLinux'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine TestWS22'
            State        = 'Online'
            OwnerGroup   = 'TestWS22'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine TestWS22.1'
            State        = 'Online'
            OwnerGroup   = 'TestWS22.1'
            ResourceType = 'Virtual Machine'
        },
        @{
            Name         = 'Virtual Machine TestWS22.2'
            State        = 'Online'
            OwnerGroup   = 'TestWS22.2'
            ResourceType = 'Virtual Machine'
        }
    )
    VMs = @(
        @{
            Name = 'brian'
            State = 'Running'
            CPUUsage = 0
            MemoryAssigned = 4096
            Uptime = '1.20:03:14.6030000'
            Status = 'Operating normally'
            Version = '10.0'
        },
        @{
            Name = 'TestLinux'
            State = 'Running'
            CPUUsage = 0
            MemoryAssigned = 0
            Uptime = '00:00:00'
            Status = 'Operating normally'
            Version = '10.0'
            Path = 'C:\fake\path\to\vm\testlinux'
        },
        @{
            Name = 'TestLinux1.2'
            State = 'Running'
            CPUUsage = 0
            MemoryAssigned = 4096
            Uptime = '6.04:26:58.6870000'
            Status = 'Operating normally'
            Version = '10.0'
            Path = 'C:\fake\path\to\vm\testlinux'
        },
        @{
            Name = 'TestWanSim'
            State = 'Running'
            CPUUsage = 0
            MemoryAssigned = 4096
            Uptime = '7.00:38:51.3840000'
            Status = 'Operating normally'
            Version = '10.0'
        }
    )
}