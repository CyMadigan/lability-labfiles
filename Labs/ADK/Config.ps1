﻿$ErrorActionPreference = 'Stop'
    # ALL nodes
    #
    Node $AllNodes.Where({ $true }).NodeName {
        # LCM
        LocalConfigurationManager {
            RebootNodeIfNeeded   = $true
            ActionAfterReboot    = 'ContinueConfiguration'
            AllowModuleOverwrite = $true
            ConfigurationMode    = 'ApplyOnly'
            RefreshMode          = 'Push'
            #CertificateID       = $node.Thumbprint
        }
    }
    # ADK nodes
    #
$ConfigData = "$(Split-Path $MyInvocation.MyCommand.Path)\Data.psd1"

Write-Host 'Generating MOFs for VM(s)' -ForegroundColor Green
SetupADK -ConfigurationData $ConfigData `
          -OutputPath 'C:\Lability\Configurations'

Test-LabConfiguration -ConfigurationData $ConfigData -Verbose

Start-LabConfiguration -ConfigurationData $ConfigData -Verbose -IgnorePendingReboot

Start-Lab -ConfigurationData $ConfigData -Verbose