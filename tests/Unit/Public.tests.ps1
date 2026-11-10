BeforeDiscovery {
    $RootItem = Get-Item $PSScriptRoot
    while ($RootItem.GetDirectories().Name -notcontains 'source')
    {
        $RootItem = $RootItem.Parent
    }
    $ProjectPath = $RootItem.FullName
    $ProjectName = (Get-ChildItem $ProjectPath\*\*.psd1 | Where-Object {
        ($_.Directory.Name -eq 'source') -and
            $(try
                {
                    Test-ModuleManifest $_.FullName -ErrorAction Stop
                }
                catch
                {
                    $false
                }) }
    ).BaseName

    Import-Module $ProjectName
}

InModuleScope $ProjectName {
    Describe 'Public MQTT commands' {
        BeforeEach {
            $client = [uPLibrary.Networking.M2Mqtt.MqttClient]::new('127.0.0.1')
            $client | Add-Member -NotePropertyName Calls -NotePropertyValue ([System.Collections.ArrayList]::new())
            $client | Add-Member -NotePropertyName FailMethod -NotePropertyValue ''
            $client | Add-Member -NotePropertyName IsConnected -NotePropertyValue $false -Force
            $client | Add-Member -MemberType ScriptMethod -Name Connect -Force -Value {
                $null = $this.Calls.Add(@{ Method = 'Connect'; Arguments = @($args) })
                if ($this.FailMethod -eq 'Connect') { throw 'connect failed' }
            }
            $client | Add-Member -MemberType ScriptMethod -Name Disconnect -Force -Value {
                $null = $this.Calls.Add(@{ Method = 'Disconnect'; Arguments = @($args) })
            }
            $client | Add-Member -MemberType ScriptMethod -Name Publish -Force -Value {
                $null = $this.Calls.Add(@{ Method = 'Publish'; Arguments = @($args) })
                if ($this.FailMethod -eq 'Publish') { throw 'publish failed' }
            }
            $client | Add-Member -MemberType ScriptMethod -Name Subscribe -Force -Value {
                $null = $this.Calls.Add(@{ Method = 'Subscribe'; Arguments = @($args) })
                if ($this.FailMethod -eq 'Subscribe') { throw 'subscribe failed' }
            }
            $client | Add-Member -MemberType ScriptMethod -Name Unsubscribe -Force -Value {
                $null = $this.Calls.Add(@{ Method = 'Unsubscribe'; Arguments = @($args) })
            }
        }

        Describe 'Connect-MQTTBroker' {
            BeforeEach {
                Mock New-Object {
                    $script:constructorArguments = $ArgumentList
                    return $client
                } -ParameterFilter { $TypeName -eq 'uPLibrary.Networking.M2Mqtt.MqttClient' }
            }

            It 'uses the default unencrypted port and an anonymous client ID' {
                $result = Connect-MQTTBroker -Hostname 'broker.example'
                $result | Should -Be $client
                $script:constructorArguments[0] | Should -Be 'broker.example'
                $script:constructorArguments[1] | Should -Be 1883
                $script:constructorArguments[2] | Should -BeFalse
                $script:constructorArguments[3] | Should -BeNullOrEmpty
                $script:constructorArguments[4] | Should -BeNullOrEmpty
                $script:constructorArguments[5] | Should -Be 'None'
                $client.Calls.Count | Should -Be 1
                $client.Calls[0].Method | Should -Be 'Connect'
                $client.Calls[0].Arguments.Count | Should -Be 1
                $client.Calls[0].Arguments[0] | Should -BeOfType [guid]
            }

            It 'uses the default TLS port when TLS is enabled' {
                $null = Connect-MQTTBroker -Hostname 'broker.example' -TLS
                $script:constructorArguments[1] | Should -Be 1884
                $script:constructorArguments[2] | Should -BeTrue
            }

            It 'passes an explicit port and credentials to the client' {
                $password = ConvertTo-SecureString 'test-password' -AsPlainText -Force
                $null = Connect-MQTTBroker -Hostname 'broker.example' -Port 8883 -TLS -Username 'test-user' -Password $password
                $script:constructorArguments[1] | Should -Be 8883
                $client.Calls[0].Arguments.Count | Should -Be 3
                $client.Calls[0].Arguments[0] | Should -BeOfType [guid]
                $client.Calls[0].Arguments[1] | Should -Be 'test-user'
                $client.Calls[0].Arguments[2] | Should -Be 'test-password'
            }

            It 'propagates connection failures' {
                $client.FailMethod = 'Connect'
                { Connect-MQTTBroker -Hostname 'broker.example' } | Should -Throw '*connect failed*'
            }
        }

        Describe 'Disconnect-MQTTBroker' {
            It 'disconnects the supplied session' {
                Disconnect-MQTTBroker -Session $client
                $client.Calls.Count | Should -Be 1
                $client.Calls[0].Method | Should -Be 'Disconnect'
            }
        }

        Describe 'Send-MQTTMessage' {
            It 'publishes UTF-8 bytes and returns the message with the requested options' {
                $payload = "hello $([char]0x00E9)"
                $message = Send-MQTTMessage -Session $client -Topic 'test/topic' -Payload $payload -QosLevel 2 -Retain
                $message.Topic | Should -Be 'test/topic'
                $message.Payload | Should -Be $payload
                $message.QosLevel | Should -Be 2
                $message.Retain | Should -BeTrue
                $client.Calls.Count | Should -Be 1
                $call = $client.Calls[0]
                $call.Method | Should -Be 'Publish'
                $call.Arguments[0] | Should -Be 'test/topic'
                [System.Text.Encoding]::UTF8.GetString($call.Arguments[1]) | Should -Be $payload
                $call.Arguments[1].Length | Should -BeGreaterThan $payload.Length
                $call.Arguments[2] | Should -Be 2
                $call.Arguments[3] | Should -BeTrue
            }

            It 'publishes with default options but returns nothing in quiet mode' {
                $result = Send-MQTTMessage -Session $client -Topic 'test/topic' -Payload 'payload' -Quiet
                $result | Should -BeNullOrEmpty
                $client.Calls.Count | Should -Be 1
                $client.Calls[0].Arguments[2] | Should -Be 0
                $client.Calls[0].Arguments[3] | Should -BeFalse
            }

            It 'returns the publish error instead of a message' {
                $client.FailMethod = 'Publish'
                $result = Send-MQTTMessage -Session $client -Topic 'test/topic' -Payload 'payload'
                $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result.ToString() | Should -Match 'publish failed'
            }
        }

        Describe 'Watch-MQTTTopic' {
            BeforeEach {
                $script:eventSourceIdentifier = $null
                $script:createdEventIdentifier = $null
                Mock Register-ObjectEvent { $script:eventSourceIdentifier = $SourceIdentifier }
                Mock Unregister-Event {}
            }

            AfterEach {
                if ($script:createdEventIdentifier)
                {
                    Remove-Event -EventIdentifier $script:createdEventIdentifier -ErrorAction SilentlyContinue
                }
            }

            It 'subscribes and cleans up when the session is disconnected' {
                Watch-MQTTTopic -Session $client -Topic 'test/#'
                $client.Calls.Count | Should -Be 2
                $client.Calls[0].Method | Should -Be 'Subscribe'
                $client.Calls[0].Arguments[0] | Should -Be 'test/#'
                $client.Calls[0].Arguments[1] | Should -Be 0
                $client.Calls[1].Method | Should -Be 'Unsubscribe'
                $client.Calls[1].Arguments[0] | Should -Be 'test/#'
                Should -Invoke Register-ObjectEvent -Times 1 -Exactly -ParameterFilter {
                    $InputObject -eq $client -and $EventName -eq 'MqttMsgPublishReceived'
                }
                Should -Invoke Unregister-Event -Times 1 -Exactly -ParameterFilter {
                    $SourceIdentifier -eq $script:eventSourceIdentifier
                }
            }

            It 'returns received messages and removes their events' {
                $client.IsConnected = $true
                $script:subscriberChecks = 0
                Mock Get-EventSubscriber {
                    $script:subscriberChecks++
                    if ($script:subscriberChecks -eq 1) { return $true }
                }
                Mock Register-ObjectEvent {
                    $eventArgs = [uPLibrary.Networking.M2Mqtt.Messages.MqttMsgPublishEventArgs]::new(
                        'test/topic', [byte[]](72, 105), $true, [byte]1, $true)
                    $event = New-Event -SourceIdentifier $SourceIdentifier -Sender $client -EventArguments $eventArgs
                    $script:createdEventIdentifier = $event.EventIdentifier
                    $script:eventSourceIdentifier = $SourceIdentifier
                }
                $message = Watch-MQTTTopic -Session $client -Topic 'test/#'
                $message.Topic | Should -Be 'test/topic'
                $message.Payload | Should -Be 'Hi'
                $message.DupFlag | Should -BeTrue
                $message.QosLevel | Should -Be 1
                $message.Retain | Should -BeTrue
                Should -ActualValue $message.PayloadUTF8ByteA -BeOfType [byte[]]
                $message.Timestamp | Should -BeOfType [datetime]
                @(Get-Event -SourceIdentifier $script:eventSourceIdentifier -ErrorAction SilentlyContinue).Count | Should -Be 0
                $client.Calls[1].Method | Should -Be 'Unsubscribe'
                Should -Invoke Unregister-Event -Times 1 -Exactly
            }

            It 'returns subscription errors and still cleans up' {
                $client.FailMethod = 'Subscribe'
                $result = Watch-MQTTTopic -Session $client -Topic 'test/#'
                $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result.ToString() | Should -Match 'subscribe failed'
                $client.Calls[1].Method | Should -Be 'Unsubscribe'
                Should -Invoke Unregister-Event -Times 1 -Exactly
            }

            It 'waits when there are no events and cleans up after the subscriber disappears' {
                $client.IsConnected = $true
                $script:subscriberChecks = 0
                Mock Get-EventSubscriber {
                    $script:subscriberChecks++
                    if ($script:subscriberChecks -eq 1) { return $true }
                }
                Mock Get-Event {
                    throw [System.ArgumentException]::new("Event with source identifier '$SourceIdentifier' does not exist.")
                }
                Mock Start-Sleep {}

                $result = Watch-MQTTTopic -Session $client -Topic 'test/#'
                $result | Should -BeNullOrEmpty
                Should -Invoke Start-Sleep -Times 1 -Exactly -ParameterFilter { $Milliseconds -eq 100 }
                $client.Calls[1].Method | Should -Be 'Unsubscribe'
                Should -Invoke Unregister-Event -Times 1 -Exactly
            }

            It 'returns unexpected event errors and still cleans up' {
                $client.IsConnected = $true
                Mock Get-EventSubscriber { return $true }
                Mock Get-Event { throw 'event failed' }

                $result = Watch-MQTTTopic -Session $client -Topic 'test/#'
                $result | Should -BeOfType [System.Management.Automation.ErrorRecord]
                $result.ToString() | Should -Match 'event failed'
                $client.Calls[1].Method | Should -Be 'Unsubscribe'
                Should -Invoke Unregister-Event -Times 1 -Exactly
            }
        }
    }
}
