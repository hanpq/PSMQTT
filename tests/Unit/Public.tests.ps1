﻿BeforeDiscovery {
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
    Describe 'Connect-MQTTBroker' {
        Mock Invoke-GarbageCollect {} -Verifiable

        Context 'default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Disconnect-MQTTBroker' {
        Mock Invoke-GarbageCollect {} -Verifiable

        Context 'default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }

    Describe 'Send-MQTTMessage' {
        Mock Invoke-GarbageCollect {} -Verifiable

        Context 'default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }


    Describe 'Watch-MQTTTopic' {
        Mock Invoke-GarbageCollect {} -Verifiable

        Context 'default' {
            It 'Should be true' {
                $true | Should -BeTrue
            }
        }
    }
}
