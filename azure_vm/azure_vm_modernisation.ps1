Param (
  [Parameter(Mandatory=$True)]
  [string]$subcriptionId,

  [Parameter(Mandatory=$True)]
  [string]$csvPath
)
Write-Output ""
Write-Output "Unmodernised VM Recoomendations"
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

#Create Log Output File
$LogFile = "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Log Output from Instance Modernisation Checks..."

#Import CSV
$CSV = Import-Csv "$csvPath\azure_vm_modernisation_table.csv"


#Set CSV Headers
"""VMName"",""ResourceGroup"",""VMSize"",""Location"",""OSType"",""NewSize""" | Out-File -Encoding ASCII -FilePath ".\azure_vm_modernisation_recommendations.csv"


#Create Hash Table of Key Pairs from CSV to determine correct moderinisation approach
$CSVTable=@{}

#Get Number of Columns in CSV
$CSVCount=(get-member -InputObject $CSV[0] -MemberType NoteProperty).count

#NOTE - Assumes Column Headers are named VersionX
foreach($TableEntry in $CSV) {
    #All but last column
    for($First=1;$First -lt $CSVCount;$First++)  {
        #Get version to upgrade from
        $FirstStr=$TableEntry.pSobject.Properties.item("Version"+$First.ToString()).Value
            
        if($FirstStr -ne "N/A") {
            #All remaining columns
            for($Second=$First+1;$Second -le $CSVCount;$Second++) {
                #Get version to upgrade to
                $SecondStr=$TableEntry.pSobject.Properties.item("Version"+$Second.ToString()).Value
        
                if($SecondStr -ne "N/A") {
                    #If from and to are valid write hash table entry
                    $CSVTable[$FirstStr]=$SecondStr
                }
            }
        }
    }
}

#Get All Azure VMs
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] Gathering all Virtual Machines..."
$AllVMs = Get-AzVM
Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")] All Virtual Machines gathered successfully"
Write-Output ""


#Process Each VM based on Hash Table Key Value Pairs
foreach ($VM in $AllVMs) {

    #If Hash Table contains the VM Size Output Recommendation
    if ($CSVTable[$VM.HardwareProfile.VmSize]) {
    
    """"+$VM.Name+""","""+$VM.ResourceGroupName+""","""+$VM.HardwareProfile.VmSize+""","""+$VM.Location+""","""+$VM.StorageProfile.OsDisk.OsType+""","""+$CSVTable[$VM.HardwareProfile.VmSize]+"""" | 
    Out-File -Encoding ASCII -FilePath ".\azure_vm_modernisation_recommendations.csv" -Append

    #Write output to Log File
    $LogFile += "`n" + "[$(get-date -Format "dd/mm/yy hh:mm:ss")] " + $VM.Name + "can be modernised to " + $CSVTable[$VM.HardwareProfile.VmSize]
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name " can be modernised to" $CSVTable[$VM.HardwareProfile.VmSize]
    } 
    
    else {
    #Write output to Log File
    $LogFile += "`n" + "[$(get-date -Format 'dd/mm/yy hh:mm:ss')] " + $VM.Name + " cannot be modernised"
    Write-Output "[$(get-date -Format "dd/mm/yy hh:mm:ss")]" $VM.Name "cannot be modernised" 
    }
}

#Export Log File
Out-File -InputObject $LogFile -FilePath ".\Moderinsation Log.txt"