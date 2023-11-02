[CmdletBinding()]
<#param ()
#>
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

Import-Module -Name $PSScriptRoot\..\WanSimMgmt.psd1 -Force
$global:testData = Import-PowerShellDataFile -Path $PSScriptRoot\WanSimMgmt.Data.psd1


InModuleScope WanSimMgmt {
    BeforeAll {

        # Mock the cmdlets used in the function
        function Get-ClusterGroup {
            param (
                $Name,
                $Cluster
            )   
        }

        function Get-ClusterResource {
            param (
                $Name,
                $Cluster
            )   
        }
        function Invoke-Command {
            param (
                $ScriptBlock,
                $Session
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
                $VmName,
                $ComputerName
            )   
        }
        function New-PSSession {
            param (
                $ComputerName
            )
        }
        function Add-ClusterVirtualMachineRole {
            param (
                $VmName,
                $Cluster
            )   
        }
        function Remove-PSSession {
            param ($Session)
        }
        function Remove-ClusterGroup {
            param (
                $Name,
                $Cluster
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
        Mock Invoke-Command { 
            $returnData = @{ 
                Logs    = [System.Collections.ArrayList]@() ; 
                Success = $true  
            }
            $returnData.Logs.Add("Starting 'mocked' remoteley executed scritpblock.") 
            $returnData.Logs.Add("Completed 'mocked' scriptblock.")
            return $returnData
        }
        Mock Add-ClusterVirtualMachineRole { 
            return $true
        }
        Mock New-PSSession {
            return $true
        }
        Mock Remove-PSSession { 
            return $true
        }
        Mock Remove-ClusterGroup { 
            return $true
        }
        Mock Get-VM { return $global:testData.VMs }   
    }

    Describe 'Invoke-WanSimDeployment' {
        It 'Function exists' {
            # Check if the function exists
            (Get-Command Invoke-WanSimDeployment) | Should -Not -BeNullOrEmpty
        }
        Context 'When called with valid paramters' {
            It 'Creates a clusterd VM' {
                Mock Get-ClusterGroup { return $global:testData.ClusterGroup }
                Mock Get-ClusterResource { return $global:testData.ClusterResource }
                $result = Invoke-WanSimDeployment -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint'
                $result | Should -Be $true
            }
            It 'Creates a standalone VM' {
                Mock Get-ClusterGroup { Throw "Not a Cluster" }
                
                $result = Invoke-WanSimDeployment -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint'
                $result | Should -Be $true
            }
            It 'Forcefully redploys a clustered VM' {
                Mock Get-ClusterGroup { return $global:testData.ClusterGroup }
                Mock Get-ClusterResource { return $global:testData.ClusterResource }
                Mock Get-VM { return $global:testData.VMs | Where-Object { $_.Name -eq "TestLinux" } }
                $result = Invoke-WanSimDeployment -WanSimName 'TestLinux' -DeploymentEndpoint 'TestEndpoint' -ForceRedeploy
                $result | Should -Be $true
            }
            It 'Forcefully redploys a standalone VM' {
                Mock Get-ClusterGroup { return $false }
                Mock Get-VM { return $global:testData.VMs | Where-Object { $_.Name -eq "TestLinux" } }
                $result = Invoke-WanSimDeployment -WanSimName 'TestLinux' -DeploymentEndpoint 'TestEndpoint' -ForceRedeploy
                $result | Should -Be $true
            }
        }
    }

    Describe 'Remove-WanSimVM' {
        It 'Function exists' {
            # Check if the function exists
            (Get-Command Remove-WanSimVM) | Should -Not -BeNullOrEmpty
        }
        Context 'When called with valid paramters' {
            It 'Removes a clusterd VM' -Tag 'tag' {
                Mock Get-ClusterGroup { return $global:testData.ClusterGroup }
                Mock Get-ClusterResource { return $global:testData.ClusterResource }
                Mock Get-VM { return $global:testData.VMs | Where-Object { $_.Name -eq "TestLinux" } }  
                $result = Remove-WanSimVM -WanSimName 'TestLinux' -DeploymentEndpoint 'TestEndpoint'
                $result | Should -Be $true
            }
            It 'Removes a standalone VM' -Tag 'tag' {
                Mock Get-ClusterGroup { return $false }
                Mock Get-ClusterResource { return $global:testData.ClusterResource }
                Mock Get-VM { return $global:testData.VMs | Where-Object { $_.Name -eq "TestLinux" } }  
                $result = Remove-WanSimVM -WanSimName 'TestLinux' -DeploymentEndpoint 'TestEndpoint'
                $result | Should -Be $true
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
                foreach ($ip in $result) {
                    [ipaddress]$ip | Should -Be $true
                }
            }
            It 'Returns multiple IPv4 addresses' {
                Mock Get-VMNetworkAdapter { 
                    return @{ 
                        IPAddresses = @( '10.10.37.58', '10.10.37.59', 'fe80::215:5dff:fe0a:a631')
                    }
                }
                $result = Get-WanSimIpAddresses -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint'
                foreach ($ip in $result) {
                    [ipaddress]$ip | Should -Be $true
                }   
            }
            It 'No VM exists and excpetion is thrown' {
                Mock Get-VM { Throw "VM not found" } 
                Mock Get-ClusterGroup { return $null }
                { Get-WanSimIpAddresses -WanSimName 'TestWanSim' -DeploymentEndpoint 'TestEndpoint' -ErrorAction SilentlyContinue } | Should -Throw
                
            }

        }
    }
}