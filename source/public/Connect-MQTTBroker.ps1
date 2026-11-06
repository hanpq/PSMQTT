function Connect-MQTTBroker
{
    <#
      .DESCRIPTION
      This function establishes a session with the MQTT broker and returns a session object that should then be passed along when using other cmdlets.

      .EXAMPLE
      $Session = Connect-MQTTBroker -Hostname mqttbroker.contoso.com -Port 1234 -Username mqttuser -Password (ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force)

      Establish a MQTT Broker session with authentication

      .EXAMPLE
      $Session = Connect-MQTTBroker -Hostname mqttbroker.contoso.com -Port 1234

      Establish a MQTT Broker session without authentication

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
    [cmdletBinding(DefaultParameterSetName = 'Anon')]
    param(
        [Parameter(Mandatory)]
        [string]
        $Hostname,

        [Parameter()]
        [int]
        $Port,

        [Parameter(Mandatory, ParameterSetName = 'Auth')]
        [string]
        $Username,

        [Parameter(Mandatory, ParameterSetName = 'Auth')]
        [securestring]
        $Password,

        [Parameter()]
        [switch]
        $TLS
    )

    #TODO implement additional connection properties like certificate ssl options etc. Different default ports based on

    # Use default ports if none are specified
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

    switch ($PSCmdlet.ParameterSetName)
    {
        'Anon'
        {
            $null = $MqttClient.Connect([guid]::NewGuid())
        }
        'Auth'
        {
            $null = $MqttClient.Connect([guid]::NewGuid(), $Username, (([pscredential]::New($Username, $Password)).GetNetworkCredential().Password))
        }
    }
    return $MqttClient

}
