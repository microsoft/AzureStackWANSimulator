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

# Thoughts...
# 1. I need to be able to deploy a single VM on an HCI Cluster
# 2. Get login creds from Key Vault.
# 2. I should validate we can log into it post deployment
# 3. I should validate Hyper-v is seeing its IP address, Linux Integration Services are installed, etc.
# 4. Functions should work in our lab, and to be used by customers in their labs.
# 5. Detect if a VM is already running with the same Name. If it is, return its IP address

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

        # Scriptblock
        $scriptBlock = {
            try {
                $returnData = @{ 
                    Logs = [System.Collections.ArrayList]@() ; 
                    Success = $false ; 
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
                        Stop-VM -Name $vmName -Force
                        $returnData.Logs.Add("Removing existing VM '$vmName'")
                        Remove-VM -Name $vmName -Force
                        $returnData.Logs.Add("Removing existing VHDX '$vhdxPath'")
                        Remove-Item -Path $vhdxPath -Force
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
                Set-VM -Name $vmName -ProcessorCount 1
                
                $returnData.Logs.Add("Setting VM Dynamic Memory to false")
                Set-VMMemory -VMName $vmName -DynamicMemoryEnabled $false
                
                $returnData.Logs.Add("Starting VM '$vmName'")
                Start-VM -VMName $vmName
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


        $return = Invoke-Command -Session $session -ScriptBlock $scriptBlock
        Write-DeployWanSimLog -Message "Remote scriptblock completed." @logParams
        Write-DeployWanSimLog -Message "Success is '$($return.Success)'" @logParams
        Write-DeployWanSimLog -Message "Logs are:" @logParams
        foreach ($log in $return.Logs) {
            Write-DeployWanSimLog -Message $log @logParams
        }
        Write-DeployWanSimLog -Message "Adding '$WanSimName' to '$DeploymentEndpoint'" @logParams
        Add-ClusterVirtualMachineRole -VMName $WanSimName -Cluster $DeploymentEndpoint -Verbose
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
}