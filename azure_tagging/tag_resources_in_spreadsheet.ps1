Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Subscription ID")]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True, HelpMessage="File Path to Tagging CSV")]
  [string]$csvPath
)
Write-Output ""
Write-Output "Tag Resources from Spreadsheet"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""
Write-Output "Before Proceeding please ensure the CSV headers are in the below format:"
Write-Output "Resource Name  |  Resource Id  |  <Tag1>  |  <Tag2>  |  <Tag3>  |  <Tag4>"
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
$csvPath = Read-Host "Please input the file path to the CSV"
$CSV = Import-Csv $CSV

foreach ($Item in $CSV) {
    
    #Get Resource and Current Tags
    $Resource = Get-AzResource -ResourceId $Item.'Resource Id'
    $ResourceTags = $Resource.Tags
    

    #Get Tag Keys from CSV
    $Keys = $CSV | Get-Member | where-object {$_.MemberType -eq "NoteProperty" -and $_.Name -ne "Resource Name" -and $_.Name -ne "Resource Id"}

    #Add each tag Key and Value to the current Tags
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering tags from spreadsheet for -" $Item."Resource Name"
    foreach ($Key in $Keys) {
        
        #Set Key Name
        $KeyName = $Key.Name

        #If Tag Value in CSV is Present Add Tag
        if ($Item.$KeyName -ne "") {

            #Tag does not currently exist
            if ($null -eq $ResourceTags.$KeyName) {
                $ResourceTags += @{ $KeyName = $Item.$KeyName }
            }

            #Tag already exists
            else {
            $ResourceTags.$KeyName = $Item.$KeyName
            }
        }
    }

    #Add the new Tags to the resource
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding tags to resource" $Item."Resource Name"
    Set-AzResource -Tag $ResourceTags -ResourceId $Item.'Resource Id' -Force
}