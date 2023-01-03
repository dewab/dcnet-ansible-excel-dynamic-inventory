#!/usr/bin/env pwsh

# Outputs an Anisble Dynamic Inventory from an Excel file

$filename = "Virtual_Machine_Standard_Build.xlsx"
$worksheet = "CSV Export (Do Not Edit)"
$GroupByCol = "OS" # Optional
$HostnameCol = "Hostname"

# Required, as Import-Excel throws an error that doesn't impact us, and breaks
# Ansible's parasing
$WarningPreference = 'silentlycontinue'

$ExcelData = Import-Excel -Path $filename -WorksheetName $worksheet | Where-Object { $_."$HostnameCol" -ne $null -and $_."$HostnameCol" -ne 0 }

# Populate HostVars Hash
$HostVars = @{}
ForEach ($hostname in $ExcelData."$HostnameCol") {
    $temphash = @{}
    $Facts = $ExcelData | Where-Object { $_."$HostnameCol" -eq $hostname }
    $FactNames = $Facts | Get-Member -MemberType Properties | Select-Object -ExpandProperty name
    $FactNames | ForEach-Object {
        $temphash.Add($_,$Facts.$_)
    }
    $HostVars.Add($hostname,$temphash)
}

if ($args -contains '--list') {
    $output = @{
        'all'   = @($ExcelData."$HostnameCol")
        '_meta' = @{}
    }

    # Add Hostvars to _meta
    $output._meta.Add("hostvars",$HostVars)
    
    # Create a group for unique entry in GroupByCol, if defined
    if ($GroupByCol -ne $null) {
        foreach ($Group in ($ExcelData."$GroupByCol" | Select-Object -Unique)) {
            $output += @{
                "$Group" = @($ExcelData | Where-Object {$_."$GroupByCol" -eq $Group} | Select-Object -Expand Hostname )
            }
        }
    }
    
    return $output | ConvertTo-Json -Depth 99
}

elseif ($args -contains '--host') {
    $hostname = $args[1]
    return $HostVars."$hostname" | ConvertTo-Json -Depth 99
}