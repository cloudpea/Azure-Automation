Param (
  [Parameter(Mandatory=$True)]
  [string]$enrollmentID,

  [Parameter(Mandatory=$True)]
  [string]$apiKey
)
Write-Output ""
Write-Output "Export Azure EA Price List"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Invoke API Request
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Invoking API Request"

$Headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$Headers.Add("Authorization", "Bearer $apiKey")

$JSON = Invoke-RestMethod -Uri https://consumption.azure.com/v2/enrollments/$enrollmentID/pricesheet -Method Get -Headers $Headers -ErrorVariable APIError -ErrorAction SilentlyContinue

if ($JSON -ne $null) {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] EA Price List Retreived successfully"
}
else {
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] API Request Error - $APIError"
}


#Convert API Response from JSON to CSV
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Converting JSON response to CSV"
$JSON | Export-CSV ".\$enrollmentID-PriceList.csv" -NoTypeInformation
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] JSON Response converted to CSV successfully"