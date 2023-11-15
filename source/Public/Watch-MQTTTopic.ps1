function Watch-MQTTTopic
{
    <#
      .DESCRIPTION
      This function will publish a message to a MQTT topic.

      .EXAMPLE
      Watch-MQTTTopic -Session $Session -Topic "topic/#"

      .PARAMETER Session
      Defines the MQTTBroker session to use

      .PARAMETER Topic
      Defines the topic to publish the message to

    #>
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uPLibrary.Networking.M2Mqtt.MqttClient]
        $Session,

        [Parameter(Mandatory)]
        [string]
        $Topic
    )

    try
    {
        Register-ObjectEvent -InputObject $Session -EventName MqttMsgPublishReceived -Action {
            [pscustomobject]@{
                TimeStamp = (Get-Date)
                Topic     = $args[1].topic
                Payload   = [System.Text.Encoding]::ASCII.GetString($args[1].Message)
            }
        }

        $Session.Subscribe($Topic, 0)

    }
    catch
    {
        $_
    }
}
