Param (
  [Parameter(Mandatory=$True)]
  [string]$username,

  [Parameter(Mandatory=$True)]
  [securestring]$password,

  [Parameter(Mandatory=$True)]
  [array]$groupNames,

)
Write-Output ""
Write-Output "Export Azure AD Users"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."

#Install and Import AzureAD Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name AzureAD -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureAD
    Import-Module -Name AzureAD
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""


#Loging with the Azure AD Admin account
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Connecting to Azure AD..."
$credentials = New-Object System.Management.Automation.PSCredential ($username, $password)
Connect-AzureAD -Credential $credentials
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Login successful"
Write-Output ""

#Create CSV Headers
$csvString = @"
DisplayName,Email

"@

foreach ($group in $groupNames) {

    #Get Group Members
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Getting Group Membership..."

    $adGroup = Get-AzureADGroup -SearchString $group
    $adGroupMembers = Get-AzureADGroupMember -ObjectId $adGroup.ObjectId

    foreach ($member in $adGroupMembers) {
        #Write Users UPN and Display Name to CSV
        $email = $Member.UserPrincipalName
        $csvString += @" 
    $($member.DisplayName),$email
    
    "@
    }
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Group Membership Complete"
}

#Output Users to CSV file
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Writing out CSV file..."
Out-File -InputObject $csvString -FilePath ".\AD Users.csv"

#Disconnect from Azure AD
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from Azure AD..."
Disconnect-AzureAD
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"
