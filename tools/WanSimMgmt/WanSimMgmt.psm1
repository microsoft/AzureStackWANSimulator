<###################################################
 #                                                 #
 #  Copyright (c) Microsoft. All rights reserved.  #
 #                                                 #
 ##################################################>

#requires -RunAsAdministrator

param(
    [Parameter(Mandatory = $false)]
    [System.String]
    $Script:logFile
)


# Defaults
$ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
$LOG_PROGRESS = "PROGRESS - "
$moduleName = 'DeployWanSim'

#############################
#  Region Logging function  #
#############################
if (!$Script:logFile) {
    $timestamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
    try {
        $logFile = Get-Variable -Name "${moduleName}LogFile" -ValueOnly -ErrorAction Stop
    }
    catch {
        $timestamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
        $logPath = (New-Item -Path "$env:SystemDrive\MASLogs" -ItemType Directory -Force).FullName
        $logFile = Join-Path -Path $logPath -ChildPath "$($moduleName)_$(${timestamp}).log"
    }    
} 

function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [System.String]
        $Function
    )
    $timestamp = [DateTime]::Now.ToString("yyyyMMdd-HHmmss")
    $logValue = "${timestamp}:${Function}:$Message"
    Write-Verbose -Message $logValue
    $logAttempt = 0
    $logSuccess = $false
    do {
        try {
            $logAttempt++
            Add-Content -Path $script:logFile -Value $logValue
            $logSuccess = $true
        }
        catch {
            Start-Sleep -Milliseconds 100
        }
    } until ($logSuccess -or ($logAttempt -ge 10))
}


#############################
# Region Exported functions #
#############################

<#
.SYNOPSIS
   Deploys a specified WanSim.

.DESCRIPTION
   The Invoke-WanSimDeployment function deploys a specified WanSim to a specified deployment endpoint.

.PARAMETER WanSimName
   The name of the WanSim to deploy.

.PARAMETER DeploymentEndpoint
   The HCI Cluster or Server to deploy against.

.EXAMPLE
   Invoke-WanSimDeployment -WanSimName "WanSim1" -DeploymentEndpoint "Endpoint1"

   Deploys the WanSim named "WanSim1" to the deployment endpoint "Endpoint1".
#>
function Invoke-WanSimDeployment {
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [System.String]
        $WanSimName,

        # The HCI Cluster or Server to deploy against.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DeploymentEndpoint,

        # Location to the directory or the actual BaseLine Image to be used. If the location is a directory, the most recent image will be used.
        [Parameter(Mandatory = $false)]
        [System.String]
        $BaseLineImagePath = 'C:\ClusterStorage\Volume1\Baseline\',

        [Parameter(Mandatory = $false)]
        [Switch]
        $ForceRedeploy,

        # WAN SIM File Path is the location the WanSims Vhdx and assiciated files will be saved.
        [Parameter(Mandatory = $false)]
        [System.String]
        $WanSimFilePath = 'C:\ClusterStorage\Volume1\WANSIM_VMs\',
        
        # VLAN ID to use for the VM
        [Parameter(Mandatory = $false)]
        [int]
        $VlanId = 2007
 
    )
    
    try { 
        $logParams = @{Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-Log -Message "Starting Invoke-WanSimDeployment for WanSim '$WanSimName' on DeploymentEndpoint '$DeploymentEndpoint'" @logParams

        # check if WansimFilePath is bound param
        $isWanSimFilePathBound = $PSBoundParameters.ContainsKey('WanSimFilePath')
        Write-Log -Message "WanSimFilePath is bound parameter is '$isWanSimFilePathBound'" @logParams
        Write-Log -Message "WanSimFilePath is '$WanSimFilePath'" @logParams
            
        Write-Log -Message "Creating pssession to '$DeploymentEndpoint'" @logParams
        $session = New-PSSession -ComputerName $DeploymentEndpoint
        Write-Log -Message "Pssession created to '$DeploymentEndpoint'" @logParams
        
        Write-Log -Message "ForceRedeploy is set to '$ForceRedeploy'" @logParams
        if (!$ForceRedeploy) {
            
            $scriptBlock = {
                try {
                    $returnData = @{ 
                        Logs        = [System.Collections.ArrayList]@() ; 
                        Clustered   = $false ;
                        $currentVMs = $null ;
                        Success     = $false  
                    }

                    # Check if Failover Cluster is installed
                    $null = $returnData.Logs.Add("Checking if Failover Cluster is installed")
                    try {
                        $clusterInstalled = Get-WindowsFeature -Name Failover-Clustering
                        $null = $returnData.Logs.Add("Failover Cluster on '$env:COMPUTERNAME' InstallState is '$($clusterInstalled.Installed)' and Installed is '$($clusterInstalled.Installed)'")
                        $null = $returnData.Logs.Add("Attempting to get clustered VMs")
                        $currentVMs = Get-ClusterGroup | Get-ClusterResource | Where-Object { $_.ResourceType -eq "Virtual Machine" }
                        Write-Log -Message "Success at getting clustered VMs. This is a clustered environment" @logParams
                        $returnData.Clustered = $true

                    }
                    catch {
                        $returnData.Clustered = $false
                        $null = $returnData.Logs.Add("Failover Cluster is not installed")
                        $null = $returnData.Logs.Add("Getting current VMs")
                        $currentVMs = Get-VM
                    }
                    $returnData.Success = $true
                    $returnData.$currentVMs = $currentVMs
                    return $returnData

                }
                catch {
                    # More detailed failure information
                    $file = $_.InvocationInfo.ScriptName
                    $line = $_.InvocationInfo.ScriptLineNumber
                    $exceptionMessage = $_.Exception.Message
                    $errorMessage = "Failure during Invoke-WanSimDeployment. Error: $file : $line >> $exceptionMessage"
                    $null = $returnData.Logs.Add($errorMessage)
                    $returnData.Success = $false
                    return $returnData
                }

                
            }
            
            # Execute the scriptblock
            Write-Log -Message "Executing remote scriptblock to get currrent VM's" @logParams
            $environmentInfo = Invoke-Command -Session $session -ScriptBlock $scriptBlock
            Write-Log -Message "Remote scriptblock completed." @logParams
            Write-Log -Message "Success is '$($environmentInfo.Success)'" @logParams
            Write-Log -Message "Logs from Pssession are:" @logParams
            foreach ($log in $return.Logs) {
                Write-Log -Message $log @logParams
            }
            if (!$environmentInfo.Success) {
                throw "Excpetion caught in script block for Invoke-WanSimDeployment. See logs for more details."
            }
            $currentVMs = $environmentInfo.currentVMs
            $clustered = $environmentInfo.Clustered
            
            if ($clustered -eq $true ) {

                # Check if OS is Server edition
                $osVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName").ProductName
                if ($osVersion -match "Server") {
                    Write-Log -Message "OS is Server edition" @logParams
                    Write-Log -Message "Checking if Failover Clusters is installed" @logParams
                    $clusterInstalled = Get-WindowsFeature -Name Failover-Clustering
                    $null = $returnData.Logs.Add("Failover Cluster on '$env:COMPUTERNAME' InstallState is '$($clusterInstalled.Installed)' and Installed is '$($clusterInstalled.Installed)'")
                    if ($clusterInstalled.Installed -eq $false) {
                        Write-Log -Message "Failover Clusters is not installed. Installing now." @logParams
                        $null = Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
                    }
                }
                else {
                    Write-Log -Message "OS is not Server edition" @logParams
                    Write-Log -Message "Checking if Rsat.FailoverCluster.Management.Tools is installed" @logParams
                    $rsatFailverCluster = Get-WindowsCapability -Name Rsat.FailoverCluster.Management.Tools* -Online 
                    if ($rsatFailverCluster.Installed -eq $false) {
                        Write-Log -Message "Rsat.FailoverCluster.Management.Tools is not installed. Installing now." @logParams
                        $null = Add-WindowsCapability -Online -Name $rsatFailverCluster.Name
                    }
                } 
            }
            
            # Check for current VM's
            if ([bool]$currentVMs) {
                if ($returnData.Clustered) {
                    Write-Log -Message "Checking if '$WanSimName' already exists on '$DeploymentEndpoint' as a clustered VM" @logParams
                    foreach ($vm in $currentVMs) {
                        if ($vm.OwnerGroup.name -eq $WanSimName) {
                            Write-Log -Message "VM '$WanSimName' already exists on '$DeploymentEndpoint'" @logParams
                            if ($vm.State -ne 'Online') {
                                Write-Log -Message "VM '$WanSimName' is not running on '$DeploymentEndpoint' setting ForceRedploy" @logParams
                                $ForceRedeploy = $true
                                break
                            }
                            else {
                                Write-Log -Message "VM '$WanSimName' is already running on '$DeploymentEndpoint'" @logParams
                                return $true
                            }
                        }                    
                    }
                }
                else {
                    Write-Log -Message "Checking if '$WanSimName' already exists on '$DeploymentEndpoint' as a non-clustered VM" @logParams
                    foreach ($vm in $currentVMs) {
                        if ($vm.Name -eq $WanSimName) {
                            Write-Log -Message "VM '$WanSimName' already exists on '$DeploymentEndpoint'" @logParams
                            if ($vm.State -ne 'Running') {
                                Write-Log -Message "VM '$WanSimName' is not running on '$DeploymentEndpoint' setting ForceRedploy" @logParams
                                $ForceRedeploy = $true
                                break
                            }
                            else {
                                Write-Log -Message "VM '$WanSimName' is already running on '$DeploymentEndpoint'" @logParams
                                return $true
                            }
                        }                    
                    }
                }
            }
        }

        if ($ForceRedeploy) {
            Write-Log -Message "ForceRedeploy is set to true, running 'Remove-WanSimVM'." @logParams
            $null = Remove-WanSimVM -WanSimName $WanSimName -DeploymentEndpoint $DeploymentEndpoint
        }
       
        # Scriptblock
        $scriptBlock = {
            try {
                $returnData = @{ 
                    Logs    = [System.Collections.ArrayList]@() ; 
                    Success = $false  
                }
                $null = $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $imagePath = $using:BaseLineImagePath
                $vlan = $using:VlanId
                $wanSimPath = $using:WanSimFilePath
                $wanSimPathBound = $using:isWanSimFilePathBound
                #$isClustered = $using:clustered


                $null = $returnData.Logs.Add("Using Get-ChildItem for BaseLineImagePath parameter.")
                $imageFile = Get-ChildItem -Path $imagePath -Filter *.vhdx | Sort-Object -Property LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
                
                # Calculate the volume number based on the hash of the $WanSimName variable
                # Convert the $WanSimName string to a byte array using UTF8 encoding
                # Calculate the sum of the byte array using the Measure-Object cmdlet
                # Select the Sum property of the Measure-Object output
                $wanSimNameHashSum = [System.Text.Encoding]::UTF8.GetBytes($vmName) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                
                # Calculate the volume number by taking the modulo (remainder) of the sum divided by 2 and adding 1. 
                # This will give us a 1 or 2.
                $volume = "Volume$($wanSimNameHashSum % 2 + 1)"
                $null = $returnData.Logs.Add("Calculated volume is: '$volume'")

                if ($wanSimPathBound) {
                    $null = $returnData.Logs.Add("Using WanSimFilePath parameter.")
                    $rootVmFilePath = $wanSimPath
                }
                else {
                    $volume = "Volume$($wanSimNameHashSum % 2 + 1)"
                    $null = $returnData.Logs.Add("Calculated volume is: '$volume'")
                    $null = $returnData.Logs.Add("Using default WanSimFilePath.")
                    $rootVmFilePath = "C:\ClusterStorage\$($volume)\WANSIM_VMs\"
                }
                $null = $returnData.Logs.Add("Root VM File Path is: '$rootVmFilePath'")
        
                if (Test-Path $image) {
                    $null = $returnData.Logs.Add("Baseline image found at '$imageFile'")
                }
                else {
                    $null = $returnData.Logs.Add("Baseline image not found at '$imageFile'")
                    throw "Baseline image not found at '$imageFile'"
                }

                $diffFileName = $vmName + '.diff' + $imageFile.Extension
                $vhdxRootPath = Join-Path -Path $rootVmFilePath -ChildPath $vmName
                $diffFilePath = Join-Path -Path $vhdxRootPath -ChildPath $diffFileName
                if (Test-Path -Path $diffFilePath) {
                    Write-Host "Removing the image file $diffFilePath"
                    $null = Remove-Item -Path $diffFilePath -Force
                }
        
                $null = $returnData.Logs.Add("Creating a new differencing image '$diffFilePath'")
                $null = New-VHD -Path $diffFilePath -ParentPath $imagePath -Differencing
                $null = $returnData.Logs.Add("New differencing image created at '$diffFilePath'")
        
                $null = $returnData.Logs.Add("Getting the management vSwitch")
                $mgmtSwitchName = Get-VMSwitch -SwitchType External | Select-Object -First 1 -ExpandProperty Name 
                $null = $returnData.Logs.Add("Management vSwitch is '$mgmtSwitchName'")
        
                $null = $returnData.Logs.Add("Creating a new VM '$vmName'")
                $null = New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 1 -VHDPath $diffFilePath -SwitchName $mgmtSwitchName -Path $rootVmFilePath
                
                $null = $returnData.Logs.Add("Setting VM Proccessor count to 1 and disabling checkpoints")
                $null = Set-VM -Name $vmName -ProcessorCount 1 -CheckpointType Disabled

                $null = $returnData.Logs.Add("Setting VM Dynamic Memory to false")
                $null = Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false

                $null = $returnData.Logs.Add("Setting VM VLAN to 2007")
                $null = Set-VMNetworkAdapterVlan -VMName $vmName -VlanId $vlan -Access
                
                $null = $returnData.Logs.Add("Starting VM '$vmName'")
                $null = Start-VM -VMName $vmName

                $returnData.Success = $true
                return $returnData
            }
            catch {
                # More detailed failure information
                $file = $_.InvocationInfo.ScriptName
                $line = $_.InvocationInfo.ScriptLineNumber
                $exceptionMessage = $_.Exception.Message
                $errorMessage = "Failure during Invoke-WanSimDeployment. Error: $file : $line >> $exceptionMessage"
                $null = $returnData.Logs.Add($errorMessage)
                $returnData.Success = $false
                return $returnData
            }  
        }

        # Execute the scriptblock
        Write-Log -Message "Executing remote scriptblock to create the WAN SIM VM" @logParams
        $return = Invoke-Command -Session $session -ScriptBlock $scriptBlock
        Write-Log -Message "Remote scriptblock completed." @logParams
        Write-Log -Message "Success is '$($return.Success)'" @logParams
        Write-Log -Message "Logs from Pssession are:" @logParams
        foreach ($log in $return.Logs) {
            Write-Log -Message $log @logParams
        }
        
        if ($clustered) {
            Write-Log -Message "Checking if '$WanSimName' is in the ClusterGroup" @logParams
            $clusterGroups = Get-ClusterGroup -Cluster $DeploymentEndpoint
            if ($WanSimName -in $clusterGroups.Name) {
                Write-Log -Message "'$WanSimName' is already in the ClusterGroup" @logParams 
            }
            else {
                Write-Log -Message "Adding '$WanSimName' to '$DeploymentEndpoint' as a clustered VM" @logParams
                $null = Add-ClusterVirtualMachineRole -VMName $WanSimName -Cluster $DeploymentEndpoint -Verbose
            }
        }
        return $true
    }
    catch {

        # More detailed failure information
        $file = $_.InvocationInfo.ScriptName
        $line = $_.InvocationInfo.ScriptLineNumber
        $exceptionMessage = $_.Exception.Message
        $errorMessage = "Failure during Invoke-WanSimDeployment. Error: $file : $line >> $exceptionMessage"
        Write-Log -Message $errorMessage @logParams
        throw $errorMessage
    }
    finally {
        if ($session) {
            Write-Log -Message "Closing pssession to '$DeploymentEndpoint'" @logParams
            $null = Remove-PSSession -Session $session
        }
    }  
}


<#
.SYNOPSIS
   Removes a specified WanSim.

.DESCRIPTION
   The Remove-WanSim function removes a specified WanSim from a specified deployment endpoint.

.PARAMETER WanSimName
   The name of the WanSim to remove.

.PARAMETER DeploymentEndpoint
   The HCI Cluster or Server to remove from.

.EXAMPLE
   Remove-WanSim -WanSimName "WanSim1" -DeploymentEndpoint "Endpoint1"

   Removes the WanSim named "WanSim1" from the deployment endpoint "Endpoint1".
#>
function Remove-WanSimVM {
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [System.String]
        $WanSimName,

        # The HCI Cluster or Server to delete a WANSIM from
        [Parameter(Mandatory = $true)]
        [System.String]
        $DeploymentEndpoint

    )

    try {
        $logParams = @{ Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-Log -Message "Starting Remove-WanSimVM" @logParams

        Write-Log -Message "Checking if there is a pssession to '$DeploymentEndpoint'" @logParams
        $currentSessions = Get-PSSession
        $keepSession = $false
        foreach ($session in $currentSessions) {
            if ($session.ComputerName -eq $DeploymentEndpoint -and $session.State -eq 'Opened') {
                Write-Log -Message "Using existing Pssesion to '$DeploymentEndpoint'" @logParams
                $keepSession = $true
                break
            }
        }
        if (!$keepSession) {
            Write-Log -Message "Creating pssession to '$DeploymentEndpoint' as no existing session was detected." @logParams
            $session = New-PSSession -ComputerName $DeploymentEndpoint
            Write-Log -Message "Pssession created to '$DeploymentEndpoint'" @logParams
        }

        ###
        # NEED TO FIX, maybe add a function to test if its a cluster or not.
        ###

        $deploymentEndpointInfo = Get-DeploymentEndpointInfo -DeploymentEndpoint $DeploymentEndpoint -Session $session
        $clusteredVM = $deploymentEndpointInfo.Clustered
        $currentVms = $deploymentEndpointInfo.CurrentVMs


        if ([bool]$clusteredVM -eq $true) {
            Write-Log -Message "VM '$WanSimName' is a clustered VM." @logParams
            $ownerNode = ($currentVms | Where-Object { $_.OwnerGroup.Name -eq $WanSimName }).OwnerNode.Name

            #$ownerNode = $clusteredVM.OwnerNode.Name
            Write-Log -Message "The owner nodes is '$ownerNode'" @logParams
            Write-Log -Message "Removing existing VM '$WanSimName' from ClusterGroup" @logParams
            $null = Remove-ClusterGroup $WanSimName -Cluster $DeploymentEndpoint -Force -RemoveResources

        }
        else {
            Write-Log -Message "VM '$WanSimName' is not a Clustered VM. Checking if its a non-clustered VM" @logParams
            try {
                $null = Get-VM -Name $WanSimName -ComputerName $DeploymentEndpoint
                $ownerNode = $DeploymentEndpoint 
            }
            catch {
                Write-Log -Message "VM '$WanSimName' is not a non-clustered VM" @logParams
                Write-Log -Message "VM '$WanSimName' does not exist. Exiting now." @logParams
                return $true
            }

        }
        $vmPath = (Get-VM -VMName $WanSimName -ComputerName $ownerNode).Path
        Write-Log -Message "vmPath path is '$vmPath'" @logParams
            
        $scriptBlock = {
            try {
                $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
                $returnData = @{ 
                    Logs    = [System.Collections.ArrayList]@() ; 
                    Success = $false ; 
                }
                $vmFilepath = $using:vmPath
                
                #
                $null = $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $null = $returnData.Logs.Add("Stopping existing VM '$vmName'")
                $null = Stop-VM -Name $vmName -Force
                $null = $returnData.Logs.Add("Removing existing VM '$vmName'")
                $null = Remove-VM -Name $vmName -Force
                $null = $returnData.Logs.Add("Removing existing all files in path '$vmFilepath'")
                $null = Remove-Item -Path $vmFilepath -Recurse -Force
                $returnData.Success = $true
                return $returnData
            }
            catch {

                # More detailed failure information
                $file = $_.InvocationInfo.ScriptName
                $line = $_.InvocationInfo.ScriptLineNumber
                $exceptionMessage = $_.Exception.Message
                $errorMessage = "Failure during Remove-WanSimVM. Error: $file : $line >> $exceptionMessage"
                $null = $returnData.Logs.Add($errorMessage)
                $returnData.Success = $false
                return $returnData
            }
        }

        # Execute the scriptblock
        Write-Log -Message "Creating a Pssession to the ownerNode '$ownerNode'" @logParams
        $ownerNodeSession = New-PSSession -ComputerName $ownerNode
        $return = Invoke-Command -Session $ownerNodeSession -ScriptBlock $scriptBlock
        Write-Log -Message "Remote scriptblock completed." @logParams
        Write-Log -Message "Success is '$($return.Success)'" @logParams
        Write-Log -Message "Logs from pssession are:" @logParams
        foreach ($log in $return.Logs) {
            Write-Log -Message $log @logParams
        }
        if (!$return.Success) {
            throw "Excpetion caught in script block for Remove-WanSimVM. See logs for more details."
        }
        return $true

    }
    catch {

        # More detailed failure information
        $file = $_.InvocationInfo.ScriptName
        $line = $_.InvocationInfo.ScriptLineNumber
        $exceptionMessage = $_.Exception.Message
        $errorMessage = "Failure during Remove-WanSimVM. Error: $file : $line >> $exceptionMessage"
        Write-Log -Message $errorMessage @logParams
        throw $errorMessage
    }
    finally {
        if ($session -and $keepSession -eq $false) {
            Write-Log -Message "Closing pssession to '$DeploymentEndpoint'" @logParams
            $null = Remove-PSSession -Session $session
        }
        if ($ownerNodeSession) {
            Write-Log -Message "Closing pssession to '$ownerNode'" @logParams
            $null = Remove-PSSession -Session $ownerNodeSession
        }
    }  
}


<#
.SYNOPSIS
   Retrieves the IP addresses of a specified WanSim.

.DESCRIPTION
   The Get-WanSimIpAddresses function retrieves the IP addresses of a specified WanSim. 
   It checks if the WanSim is in the ClusterGroup and retrieves the IP addresses accordingly.

.PARAMETER WanSimName
   The name of the WanSim for which to retrieve the IP addresses.

.PARAMETER DeploymentEndpoint
   The HCI Cluster or Server to deploy against.

.EXAMPLE
   Get-WanSimIpAddresses -WanSimName "WanSim1" -DeploymentEndpoint "Endpoint1"

   Retrieves the IP addresses of the WanSim named "WanSim1" on the deployment endpoint "Endpoint1".
#>
function Get-WanSimIpAddresses {
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [System.String]
        $WanSimName,

        # The HCI Cluster or Server to deploy against.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DeploymentEndpoint
 
    )

    try {
        $logParams = @{ Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-Log -Message "Starting Get-WanSimIPaddresses for WanSim '$WanSimName' on DeploymentEndpoint '$DeploymentEndpoint'" @logParams

        Write-Log -Message "Checking if '$WanSimName' is in the ClusterGroup" @logParams
        $clusteredVM = Get-ClusterGroup -Name $WanSimName -Cluster $DeploymentEndpoint -ErrorAction SilentlyContinue
        if ([bool]$clusteredVM -eq $true) {
            Write-Log -Message "'$WanSimName' is in a ClusterGroup." @logParams
            $ownerNode = $clusteredVM.OwnerNode.Name
            Write-Log -Message "The owner nodes is '$ownerNode'" @logParams
        }
        else {
            Write-Log -Message "VM '$WanSimName' is not a Clustered VM. Checking if its a non-clustered VM" @logParams
            try {
                $null = Get-VM -Name $WanSimName -ComputerName $DeploymentEndpoint
                $ownerNode = $DeploymentEndpoint 
            }
            catch {
                Write-Log -Message "VM '$WanSimName' is not a non-clustered VM" @logParams
                Write-Log -Message "VM '$WanSimName' does not exist. Exiting now." @logParams
                Throw "VM '$WanSimName' does not exist on on DeploymentEndpoint '$DeploymentEndpoint'. Exiting now."
            }
        }
        Write-Log -Message "Getting the VMNetworkAdapterInfo for '$WanSimName' on '$ownerNode'" @logParams
        $vmNetworkAdapterInfo = (Get-VMNetworkAdapter -VMName $WanSimName -ComputerName $ownerNode)
        $ipAddresses = $vmNetworkAdapterInfo.IPAddresses | Where-Object { $_ -notmatch '^fe80:' }
        $ipAddresses | ForEach-Object { Write-Log -Message "IP Address is: $_" @logParams }
        return $ipAddresses
    }
    catch {

        # More detailed failure information
        $file = $_.InvocationInfo.ScriptName
        $line = $_.InvocationInfo.ScriptLineNumber
        $exceptionMessage = $_.Exception.Message
        $errorMessage = "Failure during Get-WanSimIPaddresses. Error: $file : $line >> $exceptionMessage"
        Write-Log -Message $errorMessage @logParams
        throw $errorMessage
    }

}

#############################
# Region Internal functions #
#############################


function Get-DeploymentEndpointInfo {
    [CmdletBinding()]
    Param (

        # The HCI Cluster or Server to deploy against.
        [Parameter(Mandatory = $true)]
        [System.String]
        $DeploymentEndpoint,

        # PS Session to the deployment endpoint
        [Parameter(Mandatory = $true)]
        [System.Management.Automation.Runspaces.PSSession]
        $Session
 
    )

    try {

        $logParams = @{ Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-Log -Message "Starting Get-DeploymentEndpointInfo for DeploymentEndpoint '$DeploymentEndpoint'" @logParams

        $scriptBlock = {
            try {
                $returnData = @{ 
                    Logs       = [System.Collections.ArrayList]@() ; 
                    Clustered  = $false ;
                    CurrentVMs = $null ;
                    Success    = $false  
                }

                # Check if Failover Cluster is installed
                $null = $returnData.Logs.Add("Checking if Failover Cluster is installed")
                try {
                    $clusterInstalled = Get-WindowsFeature -Name Failover-Clustering
                    $null = $returnData.Logs.Add("Failover Cluster on '$env:COMPUTERNAME' InstallState is '$($clusterInstalled.Installed)' and Installed is '$($clusterInstalled.Installed)'")
                    $null = $returnData.Logs.Add("Attempting to get clustered VMs")
                    $currentVMs = Get-ClusterGroup | Get-ClusterResource | Where-Object { $_.ResourceType -eq "Virtual Machine" }
                    $null = $returnData.Logs.Add("Success at getting clustered VMs. This is a clustered environment")
                    $returnData.Clustered = $true

                }
                catch {
                    $file = $_.InvocationInfo.ScriptName
                    $line = $_.InvocationInfo.ScriptLineNumber
                    $exceptionMessage = $_.Exception.Message
                    $errorMessage = "Exception in try block. Error: $file : $line >> $exceptionMessage"
                    $null = $returnData.Logs.Add($errorMessage)
                    $returnData.Clustered = $false
                    $null = $returnData.Logs.Add("Failover Cluster is not installed")
                    $null = $returnData.Logs.Add("Getting current VMs")
                    $currentVMs = Get-VM
                }
                $returnData.Success = $true
                $returnData.CurrentVMs = $currentVMs
                return $returnData

            }
            catch {
                # More detailed failure information
                $file = $_.InvocationInfo.ScriptName
                $line = $_.InvocationInfo.ScriptLineNumber
                $exceptionMessage = $_.Exception.Message
                $errorMessage = "Failure during Get-DeploymentEndpointInfo. Error: $file : $line >> $exceptionMessage"
                $null = $returnData.Logs.Add($errorMessage)
                $returnData.Success = $false
                return $returnData
            }

            
        }
        
        # Execute the scriptblock
        Write-Log -Message "Executing remote scriptblock to determine if the wansim is clusterd and get current VM's" @logParams
        $environmentInfo = Invoke-Command -Session $Session -ScriptBlock $scriptBlock
        Write-Log -Message "Remote scriptblock completed." @logParams
        Write-Log -Message "Success is '$($environmentInfo.Success)'" @logParams
        Write-Log -Message "Logs from pssession are:" @logParams
        foreach ($log in $environmentInfo.Logs) {
            Write-Log -Message $log @logParams
        }
        if (!$environmentInfo.Success) {
            throw "Excpetion caught in script block for Remove-WanSimVM. See logs for more details."
        }

        $clustered = $environmentInfo.Clustered
            
        if ($clustered -eq $true -and $Global:TOOLS_INSTALLED -eq $false) {

            # Check if OS is Server edition
            $osVersion = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name "ProductName").ProductName
            if ($osVersion -match "Server") {
                Write-Log -Message "OS is Server edition" @logParams
                Write-Log -Message "Checking if Failover Clusters is installed" @logParams
                $clusterInstalled = Get-WindowsFeature -Name Failover-Clustering
                $null = $returnData.Logs.Add("Failover Cluster on '$env:COMPUTERNAME' InstallState is '$($clusterInstalled.Installed)' and Installed is '$($clusterInstalled.Installed)'")
                if ($clusterInstalled.Installed -eq $false) {
                    Write-Log -Message "Failover Clusters is not installed. Installing now." @logParams
                    $null = Install-WindowsFeature -Name Failover-Clustering -IncludeManagementTools
                    $Global:TOOLS_INSTALLED = $true
                }
            }
            else {
                Write-Log -Message "OS is not Server edition" @logParams
                Write-Log -Message "Checking if Rsat.FailoverCluster.Management.Tools is installed" @logParams
                $rsatFailverCluster = Get-WindowsCapability -Name Rsat.FailoverCluster.Management.Tools* -Online 
                if ($rsatFailverCluster.Installed -eq $false) {
                    Write-Log -Message "Rsat.FailoverCluster.Management.Tools is not installed. Installing now." @logParams
                    $null = Add-WindowsCapability -Online -Name $rsatFailverCluster.Name
                    $Global:TOOLS_INSTALLED = $true
                }
            } 
        }


        return $environmentInfo

    }
    catch {
            
        # More detailed failure information
        $file = $_.InvocationInfo.ScriptName
        $line = $_.InvocationInfo.ScriptLineNumber
        $exceptionMessage = $_.Exception.Message
        $errorMessage = "Failure during Get-DeploymentEndpointInfo. Error: $file : $line >> $exceptionMessage"
        Write-Log -Message $errorMessage @logParams
        throw $errorMessage
    }
}