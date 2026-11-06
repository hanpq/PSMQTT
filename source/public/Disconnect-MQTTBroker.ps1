function Disconnect-MQTTBroker
{
    <#
      .DESCRIPTION
      This function will disconnect a MQTTBroker session

      .EXAMPLE
      Disconnect-MQTTBroker -Session $Session

      .PARAMETER Session
      Defines the MQTTBroker session to use

    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uPLibrary.Networking.M2Mqtt.MqttClient]
        $Session
    )

    $Session.Disconnect()
}
