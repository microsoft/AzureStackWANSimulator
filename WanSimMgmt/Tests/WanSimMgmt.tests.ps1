[CmdletBinding()]
<#param ()
#>
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

Import-Module -Name $PSScriptRoot\..\WanSimMgmt.psm1 -Force


InModuleScope WanSimMgmt {
    BeforeAll {

        # Mock the cmdlets used in the function
        function Get-ClusterGroup {
            param (
                $Name,
                $Cluster
            )   
        }
        function Get-VMNetworkAdapter {
            param (
                $VMName,
                $ComputerName
            )   
        }
        function Get-VM {
            param (
                $Name,
                $ComputerName
            )   
        }
        Mock Get-ClusterGroup { 
            return @{ 
                OwnerNode = @{ 
                    Name = 'Node1' 
                }
            }
        }
        Mock Get-VMNetworkAdapter { 
            return @{ 
                IPAddresses = @( '10.10.37.58', 'fe80::215:5dff:fe0a:a631')
            }
        }
    }

    Describe 'Get-WanSimIpAddresses' {
        It 'Function exists' {
            # Check if the function exists
            (Get-Command Get-WanSimIpAddresses) | Should -Not -BeNullOrEmpty
        }

        Context 'When called with valid parameters' {
            It 'Clustered VM Returns an IP address' {
                $result = Get-WanSimIpAddresses -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint'

                # Check if the result is an array
                [ipaddress]$result | Should -Be $true
            }
            It 'Standalone VM Returns an IP address' {
                Mock Get-ClusterGroup { return $null }
                Mock Get-VM { return $true } 
                
                $result = Get-WanSimIpAddresses -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint'

            # Check if the result is an array
            [ipaddress]$result | Should -Be $true
        }
    }
}
}