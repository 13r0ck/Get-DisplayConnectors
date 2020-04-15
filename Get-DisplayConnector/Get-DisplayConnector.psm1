function Get-DisplayConnector {
    [CmdletBinding()]
    PARAM (
    [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
    [String[]]$ComputerName = $env:ComputerName
    )

    #List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later down.
    $ManufacturerHash = @{
    "AAC" = "AcerView";
    "ACR" = "Acer";
    "ACI" = " Asus";
    "APP" = "Apple Computer";
    "AUO" = "Asus";
    "CMO" = "Acer";
    "CPQ" = "Compaq";
    "DEL" = "Dell";
    "HWP" = "HP";
    "LEN" = "Lenovo";
    "SAN" = "Samsung";
    "SAM" = "Samsung";
    "SNY" = "Sony";
    "SRC" = "Shamrock";
    "SUN" = "Sun Microsystems";
    "SEC" = "Hewlett-Packard";
    "TAT" = "Tatung";
    "TOS" = "Toshiba";
    "TSB" = "Toshiba";
    "VSC" = "ViewSonic";
    "UNK" = "Unknown";
    "_YV" = "Fujitsu";
    }


    #Takes each computer specified and runs the following code:
    ForEach ($Computer in $ComputerName) {

    #Grabs the Monitor objects from WMI
    $Monitors = Get-WmiObject -Namespace "root\WMI" -Class "WMIMonitorID" -ComputerName $Computer -ErrorAction SilentlyContinue

    #Creates an empty array to hold the data
    $Monitor_Array = @()


    #Takes each monitor object found and runs the following code:
    ForEach ($Monitor in $Monitors) {

    #Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
    If ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName) -ne $null) {
    $Mon_Model = ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace("$([char]0x0000)","")
    } else {
    $Mon_Model = $null
    }
    $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace("$([char]0x0000)","")
    $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace("$([char]0x0000)","")
    $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace("$([char]0x0000)","")


    #Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
    $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
    If ($Mon_Manufacturer_Friendly -eq $null) {
    $Mon_Manufacturer_Friendly = $Mon_Manufacturer
    }

    #Creates a custom monitor object and fills it with 4 NoteProperty members and the respective data
    $Monitor_Obj = [PSCustomObject]@{
    Manufacturer = $Mon_Manufacturer_Friendly
    Model = $Mon_Model
    SerialNumber = $Mon_Serial_Number
    AttachedComputer = $Mon_Attached_Computer
    }

    #Appends the object to the array
    $Monitor_Array += $Monitor_Obj

    } #End ForEach Monitor

    #Outputs the Array
    $Monitor_Array

    } #End ForEach Computer

    $possible_connetions = @{
        "-2"     = "Not Assigned";
        "-1"     = "Connection type unknown";
        "0"      = "VGA";
        "1"      = "S-video";
        "2"      = "Composite video";
        "3"      = "Component video";
        "4"      = "DVI";
        "5"      = "HDMI";
        "6"      = "Low Voltage Differential Swing (LVDS) or Mobile Industry Processor Interface (MIPI) Digital Serial Interface (DSI) connector";
        "8"      = "D-Jpn connector";
        "9"      = "SDI connector";
        "10"     = "External Display Port";
        "11"     = "Embedded Display Port";
        "12"     = "External Unified Display Interface (UDI)";
        "13"     = "Embedded UDI";
        "14"     = "External display device through a dongle cable that supports SDTV";
        "15"     = "Display device wirelessly through a Miracast connected session";
        "16"     = "Connects internally to a display device";
    
    }
    if ($PSVersionTable.PSVersion.Major -lt 3) { #In powershell 3 and above Get-WMIObject was replaced with Get-CimInstance
        $monitors = Get-WmiObject -Namespace root\wmi -Class WmiMonitorConnectionParams;
    } else {
        $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorConnectionParams;
    }
    Write-Host "`n----------------- Active Connections -----------------"
    foreach ($connector in $monitors.VideoOutputTechnology) {
        if ($connector -ge -2 -and $connector -le 16) {
            $connector = [int]$connector #For some reason Powershell 2.0 will not search the hashtable correctly if this is not an int :/
            Write-Host + $possible_connetions."$connector";
        }
    };
    Write-Host "`n----------------- Connected Monitors -----------------"
}

Set-Alias -Name GDC -Value Get-DisplayConnector
Export-ModuleMember -Function Get-DisplayConnector -Alias GDC

########## - Notes - ##########

# This script needs to add the abillity to check from USB to display adapters, and if so. Do not report them as a display. Report as USB device, and have tech lookup what the adapter converts to