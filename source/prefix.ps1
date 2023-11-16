# The content of this file will be prepended to the top of the psm1 module file. This is useful for custom module setup is needed on import.

# Add M2Mqtt dependency library
Add-Type -Path "$PSScriptRoot\Include\M2Mqtt.Net.dll"

# Import custom formatting
Update-FormatData -AppendPath "$PSScriptRoot\Include\PSMQTT.Format.ps1xml"
