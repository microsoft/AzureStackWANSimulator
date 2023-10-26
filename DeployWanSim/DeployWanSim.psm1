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
$LOG_PROGRESS = "PROGRESS - "
$moduleName = 'DeployWanSim'

# Logging setup
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

function Write-DeployWanSimLog {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Message,

        [System.String]
        $Function
    )

    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop

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
        $ForceRedeploy 

       
    )
    
    try { 
        $logParams = @{Function = $MyInvocation.MyCommand.Name; Verbose = $true }
        Write-DeployWanSimLog -Message "Creating pssession to '$DeploymentEndpoint'" @logParams
        $session = New-PSSession -ComputerName $DeploymentEndpoint
        Write-DeployWanSimLog -Message "pssession created to '$DeploymentEndpoint'" @logParams

        if ($ForceRedeploy) {
            $clusterGroups = Get-ClusterGroup -Cluster $DeploymentEndpoint
            if ($WanSimName -in $clusterGroups.Name) {
                Write-DeployWanSimLog -Message "ForceRedeploy is set to true. Removing existing VM '$WanSimName' from ClusterGroup" @logParams
                $null = Remove-ClusterGroup $WanSimName -Cluster $DeploymentEndpoint -Force -RemoveResources -ErrorAction Stop
            }
        }

        # Scriptblock
        $scriptBlock = {
            try {
                $returnData = @{ 
                    Logs      = [System.Collections.ArrayList]@() ; 
                    Success   = $false ; 
                    IpAddress = $null 
                }
                $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $imagePath = $using:BaseLineImagePath
                $redeploy = $using:ForceRedeploy
        
                $currentVMs = Get-VM 
                if ($vmName -in $currentVMs.Name) {
                    if ($redeploy) {
                        $returnData.Logs.Add("ForceRedeploy is set to true. Removing existing VM '$vmName'")
                        $vhdxPath = (Get-VM -VMName $vmName | Select-Object VMId | Get-VHD).Path 
                        $returnData.Logs.Add("Stopping existing VM '$vmName'")
                        $null = Stop-VM -Name $vmName -Force
                        $returnData.Logs.Add("Removing existing VM '$vmName'")
                        $null = Remove-VM -Name $vmName -Force
                        $returnData.Logs.Add("Removing existing VHDX '$vhdxPath'")
                        $null = Remove-Item -Path $vhdxPath -Force

                    }
                    else {
                        $returnData.Logs.Add("ForceRedeploy is set to false. Returning the IP address of the existing VM.")
                        $returnData.IpAddress = (Get-VMNetworkAdapter -VMName $vmName).IpAddresses[0]
                        $returnData.Success = $true
                        return $returnData
                    }
                }
                else {
                    $returnData.Logs.Add("VM '$vmName' does not exist.")
                }
                
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
                $diffFilePath = Join-Path -Path  "C:\ClusterStorage\$($volume)\VirtualMachines\" -ChildPath $diffFileName
        
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
                $null = New-VM -Name $vmName -MemoryStartupBytes 4GB -Generation 1 -VHDPath $diffFilePath -SwitchName $mgmtSwitchName -Path 'C:\ClusterStorage\Volume1\'
                
                $returnData.Logs.Add("Setting VM Proccessor count to 1")
                $null = Set-VM -Name $vmName -ProcessorCount 1
                
                $returnData.Logs.Add("Setting VM Dynamic Memory to false")
                $null = Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
                
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
        Write-DeployWanSimLog -Message "Remote scriptblock completed." @logParams
        Write-DeployWanSimLog -Message "Success is '$($return.Success)'" @logParams
        Write-DeployWanSimLog -Message "Logs from pssession are:" @logParams
        foreach ($log in $return.Logs) {
            Write-DeployWanSimLog -Message $log @logParams
        }
        
        $clusterGroups = Get-ClusterGroup -Cluster $DeploymentEndpoint
        if ($WanSimName -in $clusterGroups.Name) {
            Write-DeployWanSimLog -Message "'$WanSimName' is already in the ClusterGroup" @logParams 
        }
        else {
            Write-DeployWanSimLog -Message "Adding '$WanSimName' to '$DeploymentEndpoint' as a clustered VM" @logParams
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
        Write-DeployWanSimLog -Message $errorMessage @logParams
        throw $errorMessage
    }
    finally {
        if ($session) {
            Write-DeployWanSimLog -Message "Closing pssession to '$DeploymentEndpoint'" @logParams
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

        # The HCI Cluster or Server to deploy against.
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
        Write-DeployWanSimLog -Message "Starting Remove-WanSimVM" @logParams

        Write-DeployWanSimLog -Message "Checking if there is a pssession to '$DeploymentEndpoint'" @logParams
        $currentSessions = Get-PSSession
        foreach ($session in $currentSessions) {
            if ($session.ComputerName -eq $DeploymentEndpoint -and $session.State -eq 'Opened')      {
                Write-DeployWanSimLog -Message "Using existing Pssesion to '$DeploymentEndpoint'" @logParams
                $keepSession = $true
                break
            }
            else {
                Write-DeployWanSimLog -Message "Creating pssession to '$DeploymentEndpoint'" @logParams
                $session = New-PSSession -ComputerName $DeploymentEndpoint
                Write-DeployWanSimLog -Message "Pssession created to '$DeploymentEndpoint'" @logParams
            }
        }

        Write-DeployWanSimLog -Message "Checking if '$WanSimName' is in the ClusterGroup" @logParams
        $clusterGroups = Get-ClusterGroup -Cluster $DeploymentEndpoint
        if ($WanSimName -in $clusterGroups.Name) {
            Write-DeployWanSimLog -Message "Removing existing VM '$WanSimName' from ClusterGroup" @logParams
            $null = Remove-ClusterGroup $WanSimName -Cluster $DeploymentEndpoint -Force -RemoveResources -ErrorAction Stop
        }
        $scriptBlock = {
            try {
                $returnData = @{ 
                    Logs      = [System.Collections.ArrayList]@() ; 
                    Success   = $false ; 
                    IpAddress = $null 
                }
                $returnData.Logs.Add("Starting remoteley executed scritpblock.")
                $vmName = $using:WanSimName
                $currentVMs = Get-VM 
                if ($vmName -in $currentVMs.Name) {
                    $vhdxPath = (Get-VM -VMName $vmName | Select-Object VMId | Get-VHD).Path
                    Write-DeployWanSimLog -Message "vhdx path is '$vhdxPath'" @logParams
                    $returnData.Logs.Add("Stopping existing VM '$vmName'")
                    $null = Stop-VM -Name $vmName -Force
                    $returnData.Logs.Add("Removing existing VM '$vmName'")
                    $null = Remove-VM -Name $vmName -Force
                    $returnData.Logs.Add("Removing existing VHDX '$vhdxPath'")
                    $null = Remove-Item -Path $vhdxPath -Force
                    $returnData.Success = $true
                }
                else {
                    $message = "VM '$vmName' does not exist. Nothing to delete"
                    $returnData.Logs.Add($message)
                    throw $message
                }
                return $returnData
            }
            catch {

                # More detailed failure information
                $file = $_.InvocationInfo.ScriptName
                $line = $_.InvocationInfo.ScriptLineNumber
                $exceptionMessage = $_.Exception.Message
                $errorMessage = "Failure during Remove-WanSimVM. Error: $file : $line >> $exceptionMessage"
                $returnData.Logs.Add($errorMessage)
                throw $errorMessage
            }
        }

        # Execute the scriptblock
        $return = Invoke-Command -Session $session -ScriptBlock $scriptBlock
        Write-DeployWanSimLog -Message "Remote scriptblock completed." @logParams
        Write-DeployWanSimLog -Message "Success is '$($return.Success)'" @logParams
        Write-DeployWanSimLog -Message "Logs from pssession are:" @logParams
        foreach ($log in $return.Logs) {
            Write-DeployWanSimLog -Message $log @logParams
        }
        return $true

    }
    catch {

        # More detailed failure information
        $file = $_.InvocationInfo.ScriptName
        $line = $_.InvocationInfo.ScriptLineNumber
        $exceptionMessage = $_.Exception.Message
        $errorMessage = "Failure during Remove-WanSimVM. Error: $file : $line >> $exceptionMessage"
        Write-DeployWanSimLog -Message $errorMessage @logParams
        throw $errorMessage
    }
    finally {
        if ($session -and $keepSession -eq $false) {
            Write-DeployWanSimLog -Message "Closing pssession to '$DeploymentEndpoint'" @logParams
            $null = Remove-PSSession -Session $session
        }
    }  
}