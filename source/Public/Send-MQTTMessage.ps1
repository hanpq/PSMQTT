function Send-MQTTMessage
{
    <#
      .DESCRIPTION
      This function will publish a message to a MQTT topic.

      .EXAMPLE
      Send-MQTTMEssage -Session $Session -Topic 'foo' -Payload '{"attribute":"value"}'

      .PARAMETER Session
      Defines the MQTTBroker session to use

      .PARAMETER Topic
      Defines the topic to publish the message to

      .PARAMETER Payload
      Defines the message as a string

      .PARAMETER Quiet
      Defines that messages are sent without outputing any objects.

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
        $Payload,

        [Parameter()]
        [switch]
        $Quiet
    )

    try
    {
        $Message = [PSMQTTMessage]::New($Topic, $Payload)

        # Publish message to MQTTBroker
        $null = $Session.Publish($Message.Topic, $Message.PayloadUTF8ByteA)

        # Return object unless quiet
        if (-not $Quiet)
        {
            return $Message
        }
    }
    catch
    {
        $_
    }
}
