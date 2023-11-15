function Send-MQTTMessage
{
    <#
      .DESCRIPTION
      This function will publish a message to a MQTT topic.

      .EXAMPLE
      Get-Something -Data 'Get me this text'

      .PARAMETER Session
      Defines the MQTTBroker session to use

      .PARAMETER Topic
      Defines the topic to publish the message to

      .PARAMETER Payload
      Defines the message as a string

    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uPLibrary.Networking.M2Mqtt.MqttClient]
        $Session,

        [Parameter(Mandatory)]
        [string]
        $Topic,

        [Parameter()]
        [string]
        $Payload
    )

    try
    {
        $PayloadBytes = [System.Text.Encoding]::UTF8.GetBytes($Payload)
        $Session.Publish($Topic, $PayloadBytes)
        [pscustomobject]@{
            TimeStamp = (Get-Date)
            Topic     = $Topic
            Payload   = $Payload
        }
    }
    catch
    {
        $_
    }
}
