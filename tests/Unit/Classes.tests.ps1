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
    Describe PSMQTTMessage {
        Context 'Type creation' {
            It 'Has created a type named PSMQTTMessage' {
                'PSMQTTMessage' -as [Type] | Should -BeOfType [Type]
            }
        }

        Context 'Constructors' {
            It 'Has a constructor constructor for sending' {
                $instance = [PSMQTTMessage]::new('topic', 'payload')
                $instance | Should -Not -BeNullOrEmpty
                $instance.GetType().Name | Should -Be 'PSMQTTMessage'
            }
        }

        Context 'Methods' {
            BeforeEach {
                $instance = [PSMQTTMessage]::new('topic', 'payload')
            }

            It 'Overrides the ToString method' {
                $instance.ToString() | Should -Be 'topic;payload'
            }
        }

        Context 'Properties' {
            BeforeEach {
                $instance = [PSMQTTMessage]::new('topic', 'payload')
            }

            It 'Has the correct properties' {
                $instance.topic | Should -Be 'topic'
                $instance.payload | Should -Be 'payload'

                # Powershell pipeline splits the array into single elements and pester
                # only evaluates the first element. By passing the value to ActualValue
                # to array is preserved and pester evaluates the array rather than the first element.
                Should -ActualValue $instance.PayloadUTF8ByteA -BeOfType [byte[]]
                $instance.Timestamp | Should -BeOfType [datetime]
                $instance.DupFlag | Should -BeFalse
                $instance.QosLevel | Should -Be 0
                $instance.Retain | Should -BeFalse
            }
        }
    }
}
