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

        # BaseLine Image Path
        [Parameter(Mandatory = $false)]
        [System.String]
        $BaseLineImagePath = 'C:\ClusterStorage\Volume1\Baseline\WANSIM-Baseline.vhdx',

        # 
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DeploymentEndpointCredential,

        [Parameter(Mandatory = $false)]
        [Switch]
        $ForceRedeploy,
        
        # VLAN ID to use for the VM
        [Parameter(Mandatory = $false)]
        [int]
        $VlanId = 2007

       
    )
    
    try { 
        $logParams = @{Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-Log -Message "Creating pssession to '$DeploymentEndpoint'" @logParams
        $session = New-PSSession -ComputerName $DeploymentEndpoint
        Write-Log -Message "Pssession created to '$DeploymentEndpoint'" @logParams

        Write-Log -Message "ForceRedeploy is set to '$ForceRedeploy'" @logParams
        if (!$ForceRedeploy){
            try {
                Write-Log -Message "Checking if this is a cluster or single server for '$DeploymentEndpoint'" @logParams
                $currentVMs = Get-ClusterGroup -Cluster $DeploymentEndpoint | Get-ClusterResource | Where-Object { $_.ResourceType -eq "Virtual Machine" }
                $clustered = $true 
                Write-Log -Message "This is a cluster" @logParams
            }
            catch {
                $currentVMs = Get-VM -ComputerName $DeploymentEndpoint -ErrorAction SilentlyContinue
                Write-Log -Message "This is a single server" @logParams
            }
            # Check for current VM's
            if ([bool]$currentVMs) {
                if ($clustered) {
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
                $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $imagePath = $using:BaseLineImagePath
                $vlan = $using:VlanId

                # Calculate the volume number based on the hash of the $WanSimName variable
                # Convert the $WanSimName string to a byte array using UTF8 encoding
                # Calculate the sum of the byte array using the Measure-Object cmdlet
                # Select the Sum property of the Measure-Object output
                $wanSimNameHashSum = [System.Text.Encoding]::UTF8.GetBytes($vmName) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
                
                # Calculate the volume number by taking the modulo (remainder) of the sum divided by 2 and adding 1. 
                # This will give us a 1 or 2.
                $volume = "Volume$($wanSimNameHashSum % 2 + 1)"
                $returnData.Logs.Add("Calculated volume is: '$volume'")
        
                if (Test-Path $imagePath) {
                    $returnData.Logs.Add("Baseline image found at '$imagePath'")
                }
                else {
                    $returnData.Logs.Add("Baseline image not found at '$imagePath'")
                    throw "Baseline image not found at '$imagePath'"
                }
                $imageFile = Get-Item -Path $imagePath
                $diffFileName = $vmName + '.diff' + $imageFile.Extension
                $rootVmFilePath =  "C:\ClusterStorage\$($volume)\WANSIM_VMs\"
                $vhdxRootPath = Join-Path -Path $rootVmFilePath -ChildPath $vmName
                $diffFilePath = Join-Path -Path $vhdxRootPath -ChildPath $diffFileName
                if (Test-Path -Path $diffFilePath) {
                    Write-Host "Removing the image file $diffFilePath"
                    Remove-Item -Path $diffFilePath -Force
                }
        
                $returnData.Logs.Add("Creating a new differencing image '$diffFilePath'")
                $null = New-VHD -Path $diffFilePath -ParentPath $imagePath -Differencing
                $returnData.Logs.Add("New differencing image created at '$diffFilePath'")
        
                $returnData.Logs.Add("Getting the management vSwitch")
                $mgmtSwitchName = Get-VMSwitch -SwitchType External | Select-Object -First 1 -ExpandProperty Name 
                $returnData.Logs.Add("Management vSwitch is '$mgmtSwitchName'")
        
                $returnData.Logs.Add("Creating a new VM '$vmName'")
                $null = New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 1 -VHDPath $diffFilePath -SwitchName $mgmtSwitchName -Path $rootVmFilePath
                
                $returnData.Logs.Add("Setting VM Proccessor count to 1 and disabling checkpoints")
                $null = Set-VM -Name $vmName -ProcessorCount 1 -CheckpointType Disabled

                $returnData.Logs.Add("Setting VM Dynamic Memory to false")
                $null = Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false

                $returnData.Logs.Add("Setting VM VLAN to 2007")
                $null = Set-VMNetworkAdapterVlan -VMName $vmName -VlanId $vlan -Access
                
                $returnData.Logs.Add("Starting VM '$vmName'")
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
                $returnData.Logs.Add($errorMessage)
                $returnData.Success = $false
                throw $errorMessage
            }  
        }

        # Execute the scriptblock
        $return = Invoke-Command -Session $session -ScriptBlock $scriptBlock
        Write-Log -Message "Remote scriptblock completed." @logParams
        Write-Log -Message "Success is '$($return.Success)'" @logParams
        Write-Log -Message "Logs from Pssession are:" @logParams
        foreach ($log in $return.Logs) {
            Write-Log -Message $log @logParams
        }
        
        $clusterGroups = Get-ClusterGroup -Cluster $DeploymentEndpoint
        if ($WanSimName -in $clusterGroups.Name) {
            Write-Log -Message "'$WanSimName' is already in the ClusterGroup" @logParams 
        }
        else {
            Write-Log -Message "Adding '$WanSimName' to '$DeploymentEndpoint' as a clustered VM" @logParams
            $null = Add-ClusterVirtualMachineRole -VMName $WanSimName -Cluster $DeploymentEndpoint -Verbose
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



function Remove-WanSimVM {
    [CmdletBinding()]
    Param (

        [Parameter(Mandatory = $true)]
        [System.String]
        $WanSimName,

        # The HCI Cluster or Server to delete a WANSIM from
        [Parameter(Mandatory = $true)]
        [System.String]
        $DeploymentEndpoint,

        # Credentials to use when connecting to the HCI Cluster or Server.
        [Parameter(Mandatory = $false)]
        [System.Management.Automation.PSCredential]
        $DeploymentEndpointCredential
       
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

        # Get-ClusterGrops servers two purposes here.
        # 1- a signal if the VM is a clustered VM
        # 2- gets information about where the VM is running on the cluster
        Write-Log -Message "Checking if '$WanSimName' is in the ClusterGroup" @logParams
        $clusteredVM = Get-ClusterGroup -Name $WanSimName -Cluster $DeploymentEndpoint -ErrorAction SilentlyContinue
        if ([bool]$clusteredVM -eq $true) {
            $ownerNode = $clusteredVM.OwnerNode.Name
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
        $vhdxPath = (Get-VM -VMName $WanSimName -ComputerName $ownerNode | Select-Object VMId | Get-VHD -ComputerName $ownerNode).Path
        Write-Log -Message "VHDX path is '$vhdxPath'" @logParams
            
        $scriptBlock = {
            try {
                $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
                $returnData = @{ 
                    Logs    = [System.Collections.ArrayList]@() ; 
                    Success = $false ; 
                }
                $diskPath = $using:vhdxPath
                $vmPath = $using:vmPath
                $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $returnData.Logs.Add("Stopping existing VM '$vmName'")
                $null = Stop-VM -Name $vmName -Force
                $returnData.Logs.Add("Removing existing VM '$vmName'")
                $null = Remove-VM -Name $vmName -Force
                $returnData.Logs.Add("Removing existing VHDX '$vmPath'")
                $null = Remove-Item -Path $vmPath -Recurse -Force
                $returnData.Success = $true
                return $returnData
            }
            catch {

                # More detailed failure information
                $file = $_.InvocationInfo.ScriptName
                $line = $_.InvocationInfo.ScriptLineNumber
                $exceptionMessage = $_.Exception.Message
                $errorMessage = "Failure during Remove-WanSimVM. Error: $file : $line >> $exceptionMessage"
                $returnData.Logs.Add($errorMessage)
                $returnData.Success = $false
                return $returnData
            }
        }

        # Execute the scriptblock
        $return = Invoke-Command -Session $session -ScriptBlock $scriptBlock
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
    }  
}


#############################
# Region Internal functions #
#############################
