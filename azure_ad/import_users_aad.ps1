Param (
    [Parameter(Mandatory = $True, HelpMessage = "Azure Tenant ID")]
    [string]$tenantId,
    
    [Parameter(Mandatory = $True, HelpMessage = "Full File Path to the CSV")]
    [string]$csvPath
)
Write-Output ""
Write-Output "Import Azure AD Users"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Install and Import AzureAD Module
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing module..."
Import-Module -Name Az -ErrorVariable ModuleError -ErrorAction SilentlyContinue
If ($ModuleError) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Installing module..."
    Install-Module -Name AzureAD
    Import-Module -Name AzureAD
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Installed module..."
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully Imported module"
Write-Output ""

#Logging with the Azure AD Admin account
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Connecting to Azure AD..."
Connect-AzureAD -TenantId $tenantId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Login successful"
Write-Output ""

#Set CSV Directory Path and Import CSVs
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing CSV..."
$users = Import-Csv -Delimiter ',' $csvPath
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Imported CSV successfully!"
Write-Output ""

#Create Invitations
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = "Hey there! Check this out. I created an invitation through PowerShell Script written by CloudPea!"
foreach ($user in $users) {
    #Check if the user exists within the directory
    $result = Get-AzureADUser -SearchString $user.DisplayName

    #Check if the user doesnt exist before sending the invitation
    if ($null -eq $result) {
        Write-Output ("Sending Invitation to "+$user.DisplayName)+"..."
        New-AzureADMSInvitation -InvitedUserEmailAddress $user.Email -InvitedUserDisplayName $user.DisplayName `
        -InviteRedirectUrl https://portal.azure.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $true
        Sleep 10
    }
    else {
        Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] User "+$invite.DisplayName+" already exists within the customers directory")
    }
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Invitiations sent successfully."
Write-Output ""

#Create AzureAD Groups
$parsedGroups = @{}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Azure AD Groups..."
foreach ($user in $users) {
    $groupName = $user.group
    if ($parsedGroups.$groupName -ne "Complete") {
        #If the group does not exist create the group
        $group = Get-AzureADGroup -SearchString $groupName
        if($null -eq $group){
        $group = New-AzureADGroup -DisplayName $groupName -MailEnabled $false -MailNickName $groupName -SecurityEnabled $true -Description "Azure AD Guest Users for $groupName"
        Sleep 10
        }
        #Add Invited Users
        foreach ($user in $users | Where-Object {$_.group -eq $groupName}) {
            $ADuser = Get-AzureADUser -SearchString $user.DisplayName
            $ADmembership = Get-AzureADUserMembership  -ObjectId $ADuser.ObjectId
            If ($ADmembership.ObjectId -contains $group.ObjectId) {
                Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] User "+$user.DisplayName+" already exists within the AD Group")
            }
            else {
                Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $ADuser.ObjectId
                Sleep 10
            }
        }
        $parsedGroups.Add($groupName, "Complete")
    }
    else {
        Write-Output ("[$(get-date -Format "dd/mm/yy hh:mm:ss")] $groupName Group already exists")
    }
}
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Azure AD Groups Created Successfully!"
Write-Output ""

#Disconnect from the Customers Azure AD
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from Azure AD..."
Disconnect-AzureAD
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"