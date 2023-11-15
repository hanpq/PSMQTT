function Connect-MQTTBroker
{
    <#
      .DESCRIPTION
      This function establishes a session with the MQTT broker and returns a session object that should then be passed along when using other cmdlets.

      .EXAMPLE
      $MQTTSession = Connect-MQTTBroker -Hostname mqttbroker.contoso.com -Port 1234 -Username mqttuser -Password (ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force)

      .PARAMETER Hostname
      Defines the hostname of the MQTT Broker to connect to

      .PARAMETER Port
      Defines the port of the MQTT Broker. Defaults to 1883.

      .PARAMETER Username
      Defines the username to use when connecting to the MQTT broker

      .PARAMETER Password
      Defines the password (securestring) to use when connecting to the MQTT Broker

      .PARAMETER TLS
      Defines if the connection should be encrypted

    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
        [int]
        $Port,

        [Parameter()]
        [string]
        $Username,

        [Parameter()]
        [securestring]
        $Password,

        [Parameter()]
        [switch]
        $TLS
    )

    #TODO implement additional connection properties like certificate ssl options etc. Different default ports based on

    if (-not $PSBoundParameters['Port'])
    {
        if ($TLS)
        {
            $Port = 1884
        }
        else
        {
            $Port = 1883
        }
    }

    $MqttClient = New-Object -TypeName uPLibrary.Networking.M2Mqtt.MqttClient -ArgumentList $Hostname, $Port, $TLS, $null, $null, 'None'
    $MqttClient.Connect([guid]::NewGuid(), $Username, ($Password.GetNetworkCredentials.Password))

    return $MqttClient
}
