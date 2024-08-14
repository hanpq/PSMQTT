function Watch-MQTTTopic
{
    <#
      .DESCRIPTION
      This function will subscribe to message published to a MQTT topic.

      .EXAMPLE
      Watch-MQTTTopic -Session $Session -Topic "topic/#"

      .PARAMETER Session
      Defines the MQTTBroker session to use

      .PARAMETER Topic
      Defines the topic to publish the message to

    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Deliberate use of WH. Function still returns objects. This write host is only used to indicate that the function is listening for events. Its rather important that such a status message is NOT picked up by the pipeline.')]
    [cmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [uPLibrary.Networking.M2Mqtt.MqttClient]
        $Session,

        [Parameter(Mandatory)]
        [string]
        $Topic
    )

    PROCESS
    {
        try
        {
            $SourceIdentifier = [guid]::NewGuid()

            Register-ObjectEvent -InputObject $Session -EventName MqttMsgPublishReceived -SourceIdentifier $SourceIdentifier

            $null = $Session.Subscribe($Topic, 0)

            Write-Host 'Listening...' -ForegroundColor Cyan

            while ($Session.IsConnected -and (Get-EventSubscriber -SourceIdentifier $SourceIdentifier))
            {
                try
                {
                    Get-Event -SourceIdentifier $SourceIdentifier -ErrorAction Stop | ForEach-Object {
                        [PSMQTTMessage]::New($PSItem)
                        Remove-Event -EventIdentifier $PSItem.EventIdentifier
                    }
                }
                catch [ArgumentException]
                {
                    if ($_.Exception.message -eq "Event with source identifier '$SourceIdentifier' does not exist.")
                    {
                        Start-Sleep -Milliseconds 100
                    }
                }
                catch
                {
                    throw $_
                }
            }
        }
        catch
        {
            $_
        }
        finally
        {
            $null = $Session.Unsubscribe($Topic)
            Unregister-Event -SourceIdentifier $SourceIdentifier
        }
    }
}
