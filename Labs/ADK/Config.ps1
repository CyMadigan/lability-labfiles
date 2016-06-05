$ErrorActionPreference = 'Stop'Configuration SetupADK {    #    # PLEASE NOTE:     # This configuration assumes that we have already downloaded the ADK files for offline use     #    Import-DscResource -ModuleName PSDesiredStateConfiguration        #
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
    }    #
    # ADK nodes
    #    Node $AllNodes.Where({ $_.Role -eq 'adk' }).NodeName {        $ADKTempFolder       = $node.ADKTempFolder        $ADKOfflineInstaller = ($ADKTempFolder + '\offline-files\adksetup.exe')        <#        #        # UNUSED AND UNTESTED        # For downloading ADK offline files - WE HAVE ALREADY DONE THIS TO SAVE BANDWIDTH/TIME        #        $ADKUrl              = 'https://download.microsoft.com/download/6/A/E/6AEA92B0-A412-4622-983E-5B305D2EBE56/adk/adksetup.exe'        $ADKLocalPath        = ($ADKTempFolder + '\baseinstaller\adksetup.exe')            File 'DownloadADKSetup' {            SourcePath = $ADKUrl            DestinationPath = $ADKLocalPath            Ensure = 'Present'            Type = 'File'        }        #>        Package 'Deployment Tools' {            Name       = "ADK Deployment Tools"            Path       = $ADKOfflineInstaller            ProductId  = "FEA31583-30A7-0951-718C-AF75DCB003B1"            Arguments  = "/features OptionId.DeploymentTools /norestart /quiet /ceip off /log $ADKTempFolder\wdk-deploytools.log"            Ensure     = "Present"            ReturnCode = 0        }        Package 'Preinstallation Environment Tools' {            Name       = "ADK Preinstallation Environment"            Path       = $ADKOfflineInstaller            ProductId  = "6FDE09DB-D711-593B-0823-D99D2A757227"            Arguments  = "/features OptionId.WindowsPreinstallationEnvironment /norestart /quiet /ceip off /log $ADKTempFolder\wdk-winpe.log"            Ensure     = "Present"            ReturnCode = 0        }        <#        Package 'User State Migration Tools' {            Name       = "ADK Deployment Tools"            Path       = $ADKOfflineInstaller            ProductId  = "0C4384AC-02DB-B4E5-E537-EE6CF22392CF"            Arguments  = "/quiet /features OptionId.UserStateMigrationTool /norestart "            Ensure     = "Present"            ReturnCode = 0        }        #>    } # node adk} #end configuration# Look for Data.psd1 in same folder that this has been run from
$ConfigData = "$(Split-Path $MyInvocation.MyCommand.Path)\Data.psd1"

Write-Host 'Generating MOFs for VM(s)' -ForegroundColor Green
SetupADK -ConfigurationData $ConfigData `
          -OutputPath 'C:\Lability\Configurations'

Test-LabConfiguration -ConfigurationData $ConfigData -Verbose

Start-LabConfiguration -ConfigurationData $ConfigData -Verbose -IgnorePendingReboot

Start-Lab -ConfigurationData $ConfigData -Verbose