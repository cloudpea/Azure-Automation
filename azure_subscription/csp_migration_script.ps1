Param (
  [Parameter(Mandatory=$True)]
  [string]$sourceSubscriptionId,

  [Parameter(Mandatory=$True)]
  [string]$destinationSubscriptionId,

  [Parameter(Mandatory=$True)]
  [string]$stagingResourceGroup,  

  [Parameter(Mandatory=$True)]
  [string]$serviceAccountUsername,

  [Parameter(Mandatory=$True)]
  [string]$serviceAccountPassword,

  [Parameter(Mandatory=$True)]
  [string]$csvFilePath
)

Write-Output ""
Write-Output "Subscription Migration Script"
Write-Output "Version 1.0.0"
Write-Output ""


## Install and Import Az Module
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


## Login to Azure Environment
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Logging in to Azure Account..."
Connect-AzAccount
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Successfully logged in to Azure Account"
Write-Output ""


## Set Subscription Id
while ($sourceSubscriptionId.Length -le 35) {
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription Id not valid"
    $sourceSubscriptionId = Read-Host "Please input your Subscription Id"
}
Select-AzSubscription -SubscriptionId $sourceSubscriptionId
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Subscription successfully selected"
Write-Output ""


## Import CSV
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Importing CSV..."
$CSV = Import-Csv $csvFilePath
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSV Imported Successfully!"
Write-Output ""



####################################################################
#        MOVE RESOURCES INTO A SINGLE STAGING RESOURCE GROUP       #
####################################################################

## Create Resource ID Array for Staging Resource Group Move
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Array of Resource IDs to Move to Staging Resource Group..."
$sourceResourceIds = @()
foreach ($resource in $CSV){
    if ($resource.'Move Supported' -eq "TRUE"){
        if ($resource.'Resource Name' -notLike '*/*'){

            # Create Variables for Top Level Resource IDs
            $sourceResourceGroup = $resource.'Resource Group'
            $resourceProvider = ($resource.'Resource Type').Split('/')[0]
            $resourceType = ($resource.'Resource Type').Split('/')[1]
            $resourceName = ($resource.'Resource Name')

            # Create Resource ID
            $resourceId = ("/subscriptions/" + "$sourceSubscriptionId" + "/resourceGroups/" + "$sourceResourceGroup" + "/providers/" + "$resourceProvider" + "/$resourceType/" + "$resourceName/")
            
            # Add Resource ID to Array
            $sourceResourceIds += $resourceId
            $resourceId = $null
        }
    }
    else {
        Write-Output ("Move Operation Not Supported - "+($resource.'Resource Name'))
    }
}
Write-Output ""
Write-Output "Source Resource ID Array Created Successfully!"
Write-Output ""

## Consolidate Resources in to Staging Resource Group
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resources to the Staging Resource Group..."

$sourceGroups = $CSV | Group-Object {$_.'Resource Group'}
foreach ($group in $sourceGroups){
    $sourceGroup = $group.Name
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resource Group - $sourceGroup"
    $resources = @($sourceResourceIds) -Like "*$sourceGroup*"

    ## Validate Move Operation to New Subcription
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validating Move Resources Operation..."

    # Get Access Token
    $PayLoad="resource=https://management.core.windows.net/&client_id=1950a258-227b-4e31-a9cf-717495945fc2&grant_type=password&username="+$serviceAccountUsername+"&scope=openid&password="+$serviceAccountPassword
    $Response=Invoke-WebRequest -Uri "https://login.microsoftonline.com/Common/oauth2/token" -Method POST -Body $PayLoad
    $accessToken=$Response| ConvertFrom-Json

    # Create POST Request Data
    $validateUri = "https://management.azure.com/subscriptions/$sourceSubscriptionId/resourceGroups/$sourceGroup/validateMoveResources?api-version=2018-02-01"
    $validateHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $validateHeaders.Add("Content-type","application/json")
    $validateHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
    $body = @{
        "resources"= $resources
        "targetResourceGroup"= "/subscriptions/$sourceSubscriptionId/resourceGroups/$stagingResourceGroup"
    } | ConvertTo-Json

    # Submit Validation POST request
    $validateResponse = Invoke-WebRequest -Method POST -Headers $validateHeaders -Uri $validateUri -Body $body -ErrorVariable ValidateError -ErrorAction SilentlyContinue
    if ($ValidateError) {
        Write-Output ""
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
        Write-Output "$ValidateError"
        exit
    }

    Do {
        # Check Validation Status Until Complete
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting 30 Seconds for Validation Results..."
        sleep 30
        $statusHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $statusHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
        $statusUri = $validateResponse.Headers.Location | Out-String
        $status = Invoke-WebRequest -Method GET -Headers $statusHeaders -Uri $statusUri -ErrorVariable StatusError -ErrorAction SilentlyContinue
        if ($StatusError) {
            Write-Output ""
            Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
            Write-Output "$StatusError"
            exit
        }
    } Until ($status.StatusCode -eq 204)

    # Move Resource to Staging Resource Group
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Move Resources Operation Validated Successfully!"
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving $sourceGroup to Staging Resource Group..."
    Move-AzResource -DestinationResourceGroupName $stagingResourceGroup -ResourceId $resources
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] $sourceGroup Moved to Staging Resource Group Successfully!"
    Write-Output ""
    Write-Output ""
}
$resources = $null
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Resources Moved to the Staging Resource Group Successfully"
Write-Output ""



####################################################################
#                MOVE RESOURCES TO CSP SUBSCRIPTION                #
####################################################################

## Create Resource Id Array for CSP Subscription Move
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Array of Resource IDs to Move to CSP Subscription..."
$stagingResourceIds = @()
foreach ($resource in $CSV){
    if ($resource.'Move Supported' -eq "TRUE"){
        if ($resource.'Resource Name' -notLike '*/*'){

            # Create Variables for Top Level Resource IDs
            $resourceProvider = ($resource.'Resource Type').Split('/')[0]
            $resourceType = ($resource.'Resource Type').Split('/')[1]
            $resourceName = ($resource.'Resource Name')

            # Create Resource ID
            $resourceId = ("/subscriptions/" + "$sourceSubscriptionId" + "/resourceGroups/" + "$stagingResourceGroup" + "/providers/" + "$resourceProvider" + "/$resourceType/" + "$resourceName/")
            
            # Add Resource Id to Array
            $stagingResourceIds += $resourceId
            $resourceId = $null
        }
    }
    else {
        Write-Output ("Move Operation Not Supported - "+($resource.'Resource Name'))
    }
}
Write-Output ""
Write-Output "Staging Resource ID Array Created Successfully!"
Write-Output ""


## Validate Move Operation to New Subcription
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validating Move Resources Operation..."

# Get Access Token
$PayLoad="resource=https://management.core.windows.net/&client_id=1950a258-227b-4e31-a9cf-717495945fc2&grant_type=password&username="+$serviceAccountUsername+"&scope=openid&password="+$serviceAccountPassword
$Response=Invoke-WebRequest -Uri "https://login.microsoftonline.com/Common/oauth2/token" -Method POST -Body $PayLoad
$accessToken=$Response| ConvertFrom-Json

# Create POST Request Data
$validateUri = "https://management.azure.com/subscriptions/$sourceSubscriptionId/resourceGroups/$stagingResourceGroup/validateMoveResources?api-version=2018-02-01"
$validateHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$validateHeaders.Add("Content-type","application/json")
$validateHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
$body = @{
    "resources"= $stagingResourceIds
    "targetResourceGroup"= "/subscriptions/$destinationSubscriptionId/resourceGroups/$stagingResourceGroup"
} | ConvertTo-Json

# Submit Validation POST request
$validateResponse = Invoke-WebRequest -Method POST -Headers $validateHeaders -Uri $validateUri -Body $body -ErrorVariable ValidateError -ErrorAction SilentlyContinue
if ($ValidateError) {
    Write-Output ""
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
    Write-Output "$ValidateError"
    exit
}

Do {
    # Check Validation Status Until Complete
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting 30 Seconds for Validation Results..."
    sleep 30 
    $statusHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $statusHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
    $statusUri = $validateResponse.Headers.Location | Out-String
    $status = Invoke-WebRequest -Method GET -Headers $statusHeaders -Uri $statusUri -ErrorVariable StatusError -ErrorAction SilentlyContinue
    if ($StatusError) {
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
        Write-Output "$StatusError"
        exit
    }
} Until ($status.StatusCode -eq 204)

## Move Resources to New Subscription
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Move Resources Operation Validated Successfully!"
Write-Output ""
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resources to CSP Subscription..."
Move-AzResource -DestinationSubscriptionId $destinationSubscriptionId -DestinationResourceGroupName $stagingResourceGroup -ResourceId $resourceIds
$resources = $null
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Resources Moved to CSP Subscription Successfully!"



#####################################################################
##          MOVE RESOURCES TO DESTINATION RESOURCE GROUPS           #
#####################################################################

## Create Resource Id Array for Destination Move
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Creating Array of Resource IDs to Move"
$destResourceIds = @()
foreach ($resource in $CSV){
    if ($resource.'Move Supported' -eq "TRUE"){
        if ($resource.'Resource Name' -notLike '*/*'){

            # Create Variables for Top Level Resource IDs
            $destResourceGroup = ($resource.'Destination Resource Group')
            $resourceProvider = ($resource.'Resource Type').Split('/')[0]
            $resourceType = ($resource.'Resource Type').Split('/')[1]
            $resourceName = ($resource.'Resource Name')

            # Create Resource ID
            $resourceId = ("/subscriptions/" + "$destinationSubscriptionId" + "/resourceGroups/" + "$destResourceGroup" + "/providers/" + "$resourceProvider" + "/$resourceType/" + "$resourceName/")
            
            # Add Resource ID to Array
            $destResourceIds += $resourceId
            $resourceId = $null
        }
    }
    else {
        Write-Output ("Move Operation Not Supported - "+($resource.'Resource Name'))
    }
}
Write-Output "Desination Resource ID Array Created Successfully!"
Write-Output ""


Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resources to Destination Resource Groups..."
$destGroups = $CSV | Group-Object {$_.'Destination Resource Group'}
foreach ($group in $destGroups){
    $destGroup = $group.Name
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resource Group - $destGroup"
    $resources = @($destResourceIds) -Like "*$destGroup*"

    #Change Resource Group in Resource IDs to Staging Resource Group
    $resources = $resources -replace $destGroup, $stagingResourceGroup

    ## Validate Move Operation to New Subcription
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validating Move Resources Operation..."

    # Get Access Token
    $PayLoad="resource=https://management.core.windows.net/&client_id=1950a258-227b-4e31-a9cf-717495945fc2&grant_type=password&username="+$serviceAccountUsername+"&scope=openid&password="+$serviceAccountPassword
    $Response=Invoke-WebRequest -Uri "https://login.microsoftonline.com/Common/oauth2/token" -Method POST -Body $PayLoad
    $accessToken=$Response| ConvertFrom-Json

    # Create POST Request Data
    $validateUri = "https://management.azure.com/subscriptions/$destinationSubscriptionId/resourceGroups/$stagingResourceGroup/validateMoveResources?api-version=2018-02-01"
    $validateHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $validateHeaders.Add("Content-type","application/json")
    $validateHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
    $body = @{
        "resources"= $resources
        "targetResourceGroup"= "/subscriptions/$destinationSubscriptionId/resourceGroups/$destGroup"
    } | ConvertTo-Json

    # Submit Validation POST request
    $validateResponse = Invoke-WebRequest -Method POST -Headers $validateHeaders -Uri $validateUri -Body $body -ErrorVariable ValidateError -ErrorAction SilentlyContinue
    if ($ValidateError) {
        Write-Output ""
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
        Write-Output "$ValidateError"
        exit
    }

    Do {
        # Check Validation Status Until Complete
        Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Waiting 30 Seconds for Validation Results..."
        sleep 30
        $statusHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $statusHeaders.Add("Authorization", "Bearer "+$accessToken.access_token)
        $statusUri = $validateResponse.Headers.Location | Out-String
        $status = Invoke-WebRequest -Method GET -Headers $statusHeaders -Uri $statusUri -ErrorVariable StatusError -ErrorAction SilentlyContinue
        if ($StatusError) {
            Write-Output ""
            Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Validation Failed with below Error:"
            Write-Output "$StatusError"
            exit
        }
    } Until ($status.StatusCode -eq 204)

    # Move Resource to Staging Resource Group
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Move Resources Operation Validated Successfully!"
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Moving Resource to $destGroup..."
    Move-AzResource -DestinationResourceGroupName $destGroup -ResourceId $resources
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] $destGroup Moved Successfully!"
    Write-Output ""
    Write-Output ""
    $resources = $null
}

Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] CSP Migration Completed Successfully!"
Write-Output ""