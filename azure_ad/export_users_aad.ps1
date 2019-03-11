Param (
  [Parameter(Mandatory=$True, HelpMessage="Azure Tenant ID")]
  [string]$tenantId,

  [Parameter(Mandatory=$True, HelpMessage="Comma-Delimitted List of Azure AD Group Name")]
  [array]$groupNames
)
Write-Output ""
Write-Output "Export Azure AD Users"
Write-Output "Version - 1.1.0"
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
Connect-AzAccount -Tenant $tenantId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Output ""


#Create CSV Headers
"""DisplayName"",""Email"",""Group""" | Out-File -Encoding ASCII -FilePath ".\AD Users.csv"

foreach ($group in $groupNames) {

    #Get Group Members
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Group Membership for $group..."

    $adGroup = Get-AzADGroup -SearchString $group
    $adGroupMembers = Get-AzADGroupMember -ObjectId $adGroup.Id

    foreach ($member in $adGroupMembers) {
        #Write Users UPN and Display Name to CSV
        """"+$member.DisplayName+""","""+$member.UserPrincipalName+""","""+$group+"""" | Out-File -Encoding ASCII -FilePath ".\AD Users.csv" -Append      
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Group Membership Complete for $group"
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Exported Successfully!"

#Disconnect from Azure AD
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from Azure AD..."
Disconnect-AzAccount
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"
