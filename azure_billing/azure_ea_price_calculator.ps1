Param (
  [Parameter(Mandatory=$True, HelpMessage="File Path to EA Price List")]
  [string]$eaPriceList,

  [Parameter(Mandatory=$True, HelpMessage="File Path to VM Recommendations CSV")]
  [string]$recommendationsCSV,
)
Write-Output ""
Write-Output "Azure EA Price Calculator"
Write-Output "Version - 1.0.0"
Write-Output "Author - Ryan Froggatt (CloudPea)"
Write-Output ""

#Create Region Map
$LocationMap = @{'eastasia'='AP East'; 'southeastasia'='AP Southeast'; 'centralus'='US Central'; 'eastus'='US East'; 'eastus2'='US East 2'; 'westus'='US West'; `
'northcentralus'='US North Central'; 'southcentralus'='US South Central'; 'northeurope'='EU North'; 'westeurope'='EU West'; 'japanwest'='JA West'; 'japaneast'='JA East'; ` 
'brazilsouth'='BR South'; 'australiaeast'='AU East'; 'australiasoutheast'='AU Southeast'; 'southindia'='IN South'; 'centralindia'='IN Central'; 'westindia'='IN West'; `
'canadacentral'='CA Central'; 'canadaeast'='CA East'; 'uksouth'='UK South'; 'ukwest'='UK West'; 'westcentralus'='US West Central'; 'westus2'='US West 2'; `
'koreacentral'='KR Central'; 'koreasouth'='KR South'; 'francecentral'='FR Central'; 'francesouth'='FR South'}

#Import EA Price List & Recommendations CSV
$PriceList = Import-CSV -Path $eaPriceList
$Recommendations = Import-CSV -Path $recommendationsCSV


foreach ($VM in $Recommendations) {

    If ($VM.OSType -eq 'Windows') {
        
        #Get VM Size from Recommendations
        $OldVMSize = $VM.VMSize
        $NewVMSize = $VM.NewSize


        #Format A Series VM Names (Required as A Series Names are formatted differently in EA Price Lists)

        #Strips 'Standard' for A Series VM Names
        If ($OldVMSize -like 'Standard_A*') {
            $OldVMSize = $OldVMSize -ireplace "Standard_",""
        }

        If ($NewVMSize -like 'Standard_A*') {
            $NewVMSize = $NewVMSize -ireplace "Standard_",""
        }

        #Fixes v2 A Series VM Names
        If ($OldVMSize -like 'A*_v2') {
            $OldVMSize = 'Standard_'+$OldVMSize
        }

        If ($NewVMSize -like 'A*_v2') {
            $NewVMSize = 'Standard_'+$NewVMSize
        }


        #Remove Letter s or S (Required as Premium Storage VMs are not listed in EA Spreadsheets)
        If($OldVMSize -like '*_*s*') {
            $OldVMSize = $OldVMSize -ireplace "s",""
            $OldVMSize = "S$OldVMSize"
        }

        If($NewVMSize -like '*_*s*') {
            $NewVMSize = $NewVMSize -ireplace "s",""
            $NewVMSize = "S$NewVMSize"
        }

        #Get VM Location from Recommendations
        $Location = $VM.Location


        #Create Search filters
        $EAOldSize = "$OldVMSize VM (Windows) - "+$LocationMap.$Location
        $EANewSize = "$NewVMSize VM (Windows) - "+$LocationMap.$Location

        #Get Objects from EA Price List
        $EAOldVM = $PriceList | Select-Object -Property * | Where-Object {$_.metername -eq $EAOldSize}
        $EANewVM = $PriceList | Select-Object -Property * | Where-Object {$_.metername -eq $EANewSize}


        # Calculate Hourly Costs
        $OldHourlyCost = $EAOldVM.unitPrice / ($EAOldVM.unitOfMeasure).Split(' ')[0]
        $NewHourlyCost = $EANewVM.unitPrice / ($EANewVM.unitOfMeasure).Split(' ')[0]

        # Write VM Cost per hour to CSV
        Write-Output "$EAOldSize = $OldHourlyCost"
        Write-Output "$EANewSize = $NewHourlyCost"

        $VM | Add-Member -NotePropertyName OldHourlyCost -NotePropertyValue $OldHourlyCost -Force
        $VM | Add-Member -NotePropertyName NewHourlyCost -NotePropertyValue $NewHourlyCost -Force
    }

    If ($VM.OSType -eq 'Linux') {

        #Get VM Size from Recommendations
        $OldVMSize = $VM.VMSize
        $NewVMSize = $VM.NewSize

        #Format A Series VM Names (Required as A Series Names are formatted differently in EA Price Lists)

        #Strips 'Standard' for A Series VM Names
        If ($OldVMSize -like 'Standard_A*') {
            $OldVMSize = $OldVMSize -ireplace "Standard_",""
        }

        If ($NewVMSize -like 'Standard_A*') {
            $NewVMSize = $NewVMSize -ireplace "Standard_",""
        }

        #Fixes v2 A Series VM Names
        If ($OldVMSize -like 'A*_v2') {
            $OldVMSize = 'Standard_'+$OldVMSize
        }

        If ($NewVMSize -like 'A*_v2') {
            $NewVMSize = 'Standard_'+$NewVMSize
        }

        #Remove Letter s or S (Required as Premium Storage VMs are not listed in EA Price Lists)
        If($OldVMSize -like '*_*s*') {
            $OldVMSize = $OldVMSize -ireplace "s",""
            $OldVMSize = "S$OldVMSize"
        }

        If($NewVMSize -like '*_*s*') {
            $NewVMSize = $NewVMSize -ireplace "s",""
            $NewVMSize = "S$NewVMSize"
        }

        #Get VM Location from Recommendations
        $Location = $VM.Location


        #Create Search filters
        $EAOldSize = "$OldVMSize VM - "+$LocationMap.$Location
        $EANewSize = "$NewVMSize VM - "+$LocationMap.$Location

        #Get Objects from EA Price List
        $EAOldVM = $PriceList | Select-Object -Property * | Where-Object {$_.metername -eq $EAOldSize}
        $EANewVM = $PriceList | Select-Object -Property * | Where-Object {$_.metername -eq $EANewSize}


        # Calculate Hourly Costs
        $OldHourlyCost = $EAOldVM.unitPrice / ($EAOldVM.unitOfMeasure).Split(' ')[0]
        $NewHourlyCost = $EANewVM.unitPrice / ($EANewVM.unitOfMeasure).Split(' ')[0]

        # Write VM Cost per hour to CSV
        Write-Output "$EAOldSize = $OldHourlyCost"
        Write-Output "$EANewSize = $NewHourlyCost"
        
        $VM | Add-Member -NotePropertyName OldHourlyCost -NotePropertyValue $OldHourlyCost -Force
        $VM | Add-Member -NotePropertyName NewHourlyCost -NotePropertyValue $NewHourlyCost -Force

    }

    #Export New CSV with Savings
    $Results = $Recommendations | Format-Table
    Out-File -FilePath "./VM Cost Saving Recommendations.csv" -Encoding ascii -InputObject $Results
}