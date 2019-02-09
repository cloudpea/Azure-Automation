Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="File Path to HUB Lincensing CSV")]
  [string]$csvPath
)
Write-Output ""
Write-Output "ANS - Enable Azure HUB Licensing"
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

#Import CSV
$CSV = Import-Csv -Path $csvPath

#Enable HUB Licensing
foreach ($VirtualMachine in $CSV) { 
    if($VirtualMachine."HUB Enabled" -ne 'True' -and $VirtualMachine.OSType -eq 'Windows') {
    Write-Output "Enabling HUB Licensing on -" $VirtualMachine.VMName

    $VM = Get-AzVm -ResourceGroupName $VirtualMachine.ResourceGroup -Name $VirtualMachine.VMName;
    $VM.LicenseType='Windows_Server'; 
    Update-AzVM -ResourceGroupName $VM.ResourceGroupName -VM $VM
    Write-Output "HUB Licensing Enabled on -" $VirtualMachine.VMName
    }
}