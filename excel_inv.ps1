#!/usr/bin/env pwsh

$configFile=".\excel_inv.ini"

function Get-IniFile 
{  
    param(  
        [parameter(Mandatory = $true)] [string] $filePath  
    )  
    $anonymous = "NoSection"
    $ini = @{}  
    switch -regex -file $filePath  
    {  
        "^\[(.+)\]$" # Section  
        {  
            $section = $matches[1]  
            $ini[$section] = @{}  
            $CommentCount = 0  
        }  
        "^(;.*)$" # Comment  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $value = $matches[1]  
            $CommentCount = $CommentCount + 1  
            $name = "Comment" + $CommentCount  
            $ini[$section][$name] = $value  
        }   
        "(.+?)\s*=\s*(.*)" # Key  
        {  
            if (!($section))  
            {  
                $section = $anonymous  
                $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
            $ini[$section][$name] = $value  
        }  
    }  
    return $ini  
}  

$config=Get-IniFile $configFile

# Outputs an Anisble Dynamic Inventory from an Excel file

$Filename = $config.defaults.Filename
$WorksheetName = $config.defaults.WorksheetName
$HostnameColumn = $config.defaults.HostnameColumn
$GroupByColumn = $config.defaults.GroupByColumn

# Optionals
# $Headers = @( 
#     "Hostname","CPU","Mem","HDDC","CDatastore","HDDD","DBlockSize", "DDatastore","HDDE","EBlockSize","EDatastore",
#     "HDDL","LBlockSIze","LDatastore","HDDT","TBlockSize","TDatastore","OS","IP1","IP1Portgroup","IP1Subnet",
#     "IP1Gateway","IP2","IP2Portgroup","IP2Subnet","IP2Gateway","IP3","IP3Portgroup","IP3Subnet","IP3Gateway",
#     "BuildOrder","VMFolder","Status","VMHost" )


# Required, as Import-Excel throws an error that doesn't impact us, and breaks
# Ansible's parasing
$WarningPreference = 'silentlycontinue'

if ($Headers) {
    $ExcelData = Import-Excel -Path $Filename -WorksheetName $WorksheetName -HeaderName $Headers -DataOnly | Where-Object { $_."$HostnameColumn" -ne $null -and $_."$HostnameColumn" -ne 0 }
} else {
    $ExcelData = Import-Excel -Path $Filename -WorksheetName $WorksheetName -DataOnly | Where-Object { $_."$HostnameColumn" -ne $null -and $_."$HostnameColumn" -ne 0 }
}

# Populate HostVars Hash
$HostVars = @{}
ForEach ($hostname in $ExcelData."$HostnameColumn") {
    $temphash = @{}
    $Facts = $ExcelData | Where-Object { $_."$HostnameColumn" -eq $hostname }
    $FactNames = $Facts | Get-Member -MemberType Properties | Select-Object -ExpandProperty name
    $FactNames | ForEach-Object {
        $temphash.Add($_,$Facts.$_)
    }
    $HostVars.Add($hostname,$temphash)
}

if ($args -contains '--list') {
    $output = @{
        'all'   = @($ExcelData."$HostnameColumn")
        '_meta' = @{}
    }

    # Add Hostvars to _meta
    $output._meta.Add("hostvars",$HostVars)
    
    # Create a group for unique entry in $GroupByColumn, if defined
    # if ($config.defaults.GroupByColumn -ne $null) {
    if ($null -ne $GroupByColumn) {
        foreach ($Group in ($ExcelData."$GroupByColumn" | Select-Object -Unique)) {
            $output += @{
                "$Group" = @($ExcelData | Where-Object {$_."$GroupByColumn" -eq $Group} | Select-Object -Expand Hostname )
            }
        }
    }
    
    return $output | ConvertTo-Json -Depth 99
}

elseif ($args -contains '--host') {
    $hostname = $args[1]
    return $HostVars."$hostname" | ConvertTo-Json -Depth 99
}
