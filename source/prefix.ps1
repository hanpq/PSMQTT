# The content of this file will be prepended to the top of the psm1 module file. This is useful for custom module setup is needed on import.

# Add M2Mqtt dependency library
Add-Type -Path "$PSScriptRoot\include\M2Mqtt.Net.dll"

# Import custom formatting
Update-FormatData -AppendPath "$PSScriptRoot\include\PSMQTT.Format.ps1xml"
