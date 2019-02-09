Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Azure VM Networking Info"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Install and Import Az Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name Az -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name Az
    Import-Module -Name Az
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""

#Login to Azure
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Connect-AzAccount
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Output ""

#Select SubscriptionId
while ($subcriptionId.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $subcriptionId = Read-Host "Please input your Subscription Id"
}
Select-AzSubscription -SubscriptionId $subcriptionId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""

#Set CSV Headers
"""VMName"",""ResourceGroup"",""VMSize"",""HUB Enabled"",""OSType"",""Virtual Network"",""IP Address""" | Out-File -Encoding ASCII -FilePath ".\Azure VM Info.csv"

#Getting HUB Licensing Info
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting HUB Licensing Information for Windows Virtual Machines"

foreach ($VM in Get-AzVm | Where-Object {$_.StorageProfile.OsDisk.OsType -eq "Windows"}) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Processing VM -" $VM.Name

    #Get HUB Licensing Status
    if ($VM.LicenseType -ne "Windows_Server") {$HUB = "False"
    }
    if ($VM.LicenseType -eq "Windows_Server") {$HUB = "True"
    }

    #Get Number of Cores
    $Cores = (Get-AzVMSize -ResourceGroupName $VM.ResourceGroupName -VMName $VM.Name | Where-Object {$_.Name -eq $VM.HardwareProfile.VmSize}).NumberOfCores

    #Calculate Required Licenses
    if ($Cores -le 8) { $Licenses = "0.5"
    }
    if ($Cores -le 16 -and $Cores -ge 9) { $Licenses = "1"
    }
    if ($Cores -ge 17) { $Licenses = "VM Size not applicable"
    }

    #Write Output for VM to CSV
    """"+$VM.Name+""","""+$VM.ResourceGroupName+""","""+$VM.HardwareProfile.VmSize+""","""+$HUB+""","""+$Cores+""","""+$VM.StorageProfile.OsDisk.OsType+""","""+$Licenses+"""" | 
    Out-File -Encoding ASCII -FilePath ".\azure_hub_licensing.csv" -Append
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] HUB Licensing Information Obtained Successfully!"