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

      .PARAMETER QosLevel
      Defines the Quality of Service level for the message.

      .PARAMETER Retain
      Defines if the message should be retained by the MQTTBroker.

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
        $Quiet,

        [Parameter()]
        [int]
        $QosLevel = 0,

        [Parameter()]
        [switch]
        $Retain
    )

    try
    {
        $Message = [PSMQTTMessage]::New($Topic, $Payload, $QosLevel, $Retain)

        # Publish message to MQTTBroker
        $null = $Session.Publish($Message.Topic, $Message.PayloadUTF8ByteA, $Message.QosLevel, $Message.Retain)

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
