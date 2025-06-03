class PSMQTTMessage
{
    [string]$Topic
    [string]$Payload
    [byte[]]$PayloadUTF8ByteA
    [datetime]$Timestamp
    [boolean]$DupFlag
    [int]$QosLevel
    [boolean]$Retain

    PSMQTTMessage(
        [string]$Topic,
        [string]$Payload,
        [int]$QosLevel,
        [boolean]$Retain
    )
    {
        $this.Topic = $Topic
        $this.Payload = $Payload
        $this.PayloadUTF8ByteA = [System.Text.Encoding]::UTF8.GetBytes($Payload)
        $this.Timestamp = (Get-Date)
        $this.QosLevel = $QosLevel
        $this.Retain = $Retain
    }

    PSMQTTMessage(
        [System.Management.Automation.PSEventArgs]$EventObject
    )
    {
        $this.Topic = $EventObject.SourceEventArgs.Topic
        $this.Payload = [System.Text.Encoding]::ASCII.GetString($EventObject.SourceEventArgs.Message)
        $this.PayloadUTF8ByteA = $EventObject.SourceEventArgs.Message
        $this.DupFlag = $EventObject.SourceEventArgs.DupFlag
        $this.QosLevel = $EventObject.SourceEventArgs.QosLevel
        $this.Retain = $EventObject.SourceEventArgs.Retain
        $this.Timestamp = $EventObject.TimeGenerated
    }

    [string] ToString ()
    {
        return ($this.Topic + ';' + $this.Payload)
    }

}
