function Disconnect-MQTTBroker
{
    <#
      .DESCRIPTION
      This function will disconnect a MQTTBroker session

      .EXAMPLE
      Get-Something -Data 'Get me this text'

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
