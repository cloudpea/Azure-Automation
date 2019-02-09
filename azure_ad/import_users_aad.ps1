Param (
  [Parameter(Mandatory=$True)]
  [string]$username,

  [Parameter(Mandatory=$True)]
  [securestring]$password,

  [Parameter(Mandatory=$True)]
  [array]$csvPath,

)
Write-Output ""
Write-Output "Import Azure AD Users"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

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

#Set CSV Directory Path and Import CSVs
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing CSV..."
$invitations = import-csv -Delimiter ',' $csvPath
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Imported CSV successfully!"
Write-Output ""


#Create Invitations
$messageInfo = New-Object Microsoft.Open.MSGraph.Model.InvitedUserMessageInfo
$messageInfo.customizedMessageBody = "Hey there! Check this out. I created an invitation through PowerShell Script written by CloudPea!"


foreach ($invite in $invitations) {
    #Check if the user exists within the directory
    $result = Get-AzureADUser -SearchString $invite.DisplayName

    #Check if the user doesnt exist before sending the invitation
    if ($result -eq $null) {
        Write-Output "Sending Invitation to " $invite.DisplayName
        New-AzureADMSInvitation -InvitedUserEmailAddress $invite.Email -InvitedUserDisplayName $invite.DisplayName -InviteRedirectUrl https://portal.azure.com -InvitedUserMessageInfo $messageInfo -SendInvitationMessage $true
    }
    else {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] User $($invite.DisplayName) already exists within the customers directory"
    }
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Invitiations sent successfully."
Write-Output ""



#Create AzureAD groups
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Guest Users Azure AD Group..."

#Check if the Guest Users Group exists
$groupName = "Guest Users"
$result = Get-AzureADGroup -SearchString $groupName
$group = $null

if ($result -eq $null) {
    #If the group does not exist create the group
    $group = New-AzureADGroup -DisplayName $groupName -MailEnabled $false -MailNickName "Guest Users" -SecurityEnabled $true -Description "Azure AD Guest Users"

}
else {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Guest User Group already exists"
    #If the Group exists then get the Group
    $group = Get-AzureADGroup -SearchString $groupName
}

#Create the users within the Guest User Group
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Adding users to the Guest Users Group..."
foreach ($invite in $invitations) {
    $user = Get-AzureADUser -SearchString $invite.DisplayName
    while (!$user) {
        Write-Output "Waiting for "$invite.DisplayName
        SLEEP 1
        $user = Get-AzureADUser -SearchString $invite.DisplayName
    }

        #Get User Membership
	    $membership = Get-AzureADUserMembership  -ObjectId $user.ObjectId

            #If user exists do nothing
            If ($membership.ObjectId -contains $group.ObjectId) {
	            Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] User" $user.DisplayName "already exists within the customers directory"
	        }
            #If the user does not exist add the user to the group
    	    else {
                Add-AzureADGroupMember -ObjectId $group.ObjectId -RefObjectId $User.ObjectId
    	    }
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Added Users to Guest Users Group"
Write-Output ""


#Disconnect from the Customers Azure AD
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Disconnecting from Azure AD..."
Disconnect-AzureAD
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully disconnected"