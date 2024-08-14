# PSMQTT

This project has adopted the following policies [![CodeOfConduct](https://img.shields.io/badge/Code%20Of%20Conduct-gray)](https://github.com/hanpq/PSMQTT/blob/main/.github/CODE_OF_CONDUCT.md) [![Contributing](https://img.shields.io/badge/Contributing-gray)](https://github.com/hanpq/PSMQTT/blob/main/.github/CONTRIBUTING.md) [![Security](https://img.shields.io/badge/Security-gray)](https://github.com/hanpq/PSMQTT/blob/main/.github/SECURITY.md)

## Project status
[![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/hanpq/PSMQTT/build.yml?branch=main&label=build&logo=github)](https://github.com/hanpq/PSMQTT/actions/workflows/build.yml) [![Codecov](https://img.shields.io/codecov/c/github/hanpq/PSMQTT?logo=codecov&token=qJqWlwMAiD)](https://codecov.io/gh/hanpq/PSMQTT) [![Platform](https://img.shields.io/powershellgallery/p/PSMQTT?logo=ReasonStudios)](https://img.shields.io/powershellgallery/p/PSMQTT) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/PSMQTT?label=downloads)](https://www.powershellgallery.com/packages/PSMQTT) [![License](https://img.shields.io/github/license/hanpq/PSMQTT)](https://github.com/hanpq/PSMQTT/blob/main/LICENSE) [![docs](https://img.shields.io/badge/docs-getps.dev-blueviolet)](https://getps.dev/modules/PSMQTT/getstarted) [![changelog](https://img.shields.io/badge/changelog-getps.dev-blueviolet)](https://github.com/hanpq/PSMQTT/blob/main/CHANGELOG.md) ![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/hanpq/PSMQTT?label=version&sort=semver) ![GitHub release (latest SemVer including pre-releases)](https://img.shields.io/github/v/release/hanpq/PSMQTT?include_prereleases&label=prerelease&sort=semver)

## About

This powershell module allows you to connect to a MQTT broker and post new messages as well as subscribing to a topic to receive new messages.

## Installation

### PowerShell Gallery

To install from the PowerShell gallery using PowerShellGet run the following command:

```powershell
Install-Module PSMQTT -Scope CurrentUser
```

## Usage

Start by connecting to the MQTT broker with `Connect-MQTTBroker`. You can connect either annonymous or with username & password

```powershell
# With username & password

$Session = Connect-MQTTBroker -Hostname mqttbroker.contoso.com -Port 1234 -Username mqttuser -Password (ConvertTo-SecureString -String 'P@ssw0rd1' -AsPlainText -Force)

# Annonymous

$Session = Connect-MQTTBroker -Hostname mqttbroker.contoso.com -Port 1234
```

To send a message to the MQTT broker use `Send-MQTTMessage`

```powershell
Send-MQTTMessage -Session $Session -Topic 'foo' -Payload '{"attribute":"value"}'
```

To subscribe to messages sent to the MQTT broker, use `Watch-MQTTTopic`

```powershell
Watch-MQTTTopic -Session $Session -Topic "topic/#"
```

You can subscribe to subtopics by using `/` and you can also use wildcards with `#` as in the example above.

One you are done you can close the session by calling `Disconnect-MQTTBroker`

```powershell
Disconnect-MQTTBroker -Session $Session
```
