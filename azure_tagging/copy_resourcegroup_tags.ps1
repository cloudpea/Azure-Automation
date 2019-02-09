Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId
)
Write-Output ""
Write-Output "Copy Resource Group Tags"
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

#Get All Azure Resources
$Resources = Get-AzResource

#Get All Azure Resource Groups
foreach ($G in Get-AzResourceGroup) {

    #If Resource Group Tags Exist Iterate Resource Groups Resources
    if ($G.Tags -ne $null) {
        foreach ($R in $Resources)
        {
            if ($R.ResourceGroupName -eq $G.ResourceGroupName) 
            {
                Write-Output ("Processing " + $R.ResourceName)
                Write-Output $G.ResourceGroupName

                #Get Resource's Tags
                $ResourceTags = $R.Tags

                #If current Resource Tag exists in its Resource Group's Tags then remove the tag. 
                if ($ResourceTags -ne $null) 
                {
                foreach ($key in $G.Tags.Keys)
                {
                    if ($ResourceTags.ContainsKey($key)) { $ResourceTags.Remove($key) }
                }
                
                #Append Resource Group's tags to Resource's Tags.
                $ResourceTags += $G.Tags

                #Write Tags in ResourceTags Variable.
                Set-AzResource -Tag $ResourceTags -ResourceId $R.ResourceId -Force
                Write-Output ("Completed " + $R.ResourceName)
                }
            }
        }
    }
}