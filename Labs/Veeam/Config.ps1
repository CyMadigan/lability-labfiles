$ErrorActionPreference = 'Stop'

# VEEAM silent installation documentation:
# https://helpcenter.veeam.com/backup/vsphere/silent_mode_prerequisites.html

# Find package name/productID:
# get-wmiobject Win32_Product | Format-Table IdentifyingNumber, Name, LocalPackage


Configuration VeeamServer {
    param (
        [ValidateNotNull()]
        [PSCredential]$Credential = (Get-Credential -Credential 'Administrator')
    )

    #
    # ConfigData variables:
    #
    # $node.NodeName                    = 'VEEAM01'
    # $node.Role                        = 'veeam'
    # $node.VeeamImageFile              = 'C:\Resources\VeeamBackup&Replication_9.0.0.902.iso'
    # $node.VeeamImageMounted           = 'V:
    # $node.Lability_Resource           = @('VeeamBackupAndReplication')

    # Import required DSC modules
    Import-DscResource -Module PSDesiredStateConfiguration
    Import-DscResource -Module xComputerManagement
    Import-DscResource -Module xSQLServer
    Import-DscResource -Module xStorage

    #
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

    #
    # VEEAM nodes
    #
    Node $AllNodes.Where({ $_.Role -eq 'veeam' }).NodeName {
        Write-Verbose "Processing:   $($node.NodeName)"

        $VeeamTempFiles     = ('C:\VeeamTemp')
        $VeeamInstallerLogs = ($VeeamTempFiles + '\InstallLogs')

        # Mount the ISO
            # Lability can automatically do this for us, but I wanted
            # to have a configuration that would work independently
            # from Lability too.

        <#
        xMountImage 'MountVeeamISO' {
            Name                 = 'Mount Veeam ISO'
            ImagePath            = $node.VeeamImageFile
            DriveLetter          = $node.VeeamImageMounted
            Ensure               = 'Present'
        }
        #>

        # Create a temp folder to save Veeam installers to
        File 'VeeamTempFolder' {
            DestinationPath = $VeeamTempFiles
            Type            = 'Directory'
            Ensure          = 'Present'
            #DependsOn       = '[xMountImage]MountVeeamISO'
        }

        # Create a temp folder for the installer log files
        File 'VeeamTempLogsFolder' {
            DestinationPath = $VeeamInstallerLogs
            Type            = 'Directory'
            Ensure          = 'Present'
            DependsOn       = '[File]VeeamTempFolder'
        }

        # Install Dot Net Framework 4.5.2
            # I had to use a script resource here as I couldn't find a detection method 
            # for the this to use the 'Package' resource :(
        Script 'DotNet4.5.2' {
            GetScript = {
                # Dot Net 4.5.2 will have a release of 379893
                return @{ Compliance = ((Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client' | Get-ItemProperty -Name 'Release' | Select-Object -ExpandProperty 'Release') -eq 379893) }
            }

            TestScript = {
                (Get-Item -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Client' | Get-ItemProperty -Name 'Release' | Select-Object -ExpandProperty 'Release') -eq 379893
            }

            SetScript = {
                # Install it
                & ($using:node.VeeamImageMounted + '\Redistr\NDP452-KB2901907-x86-x64-AllOS-ENU.exe') /q

                # Tell the LCM to reboot the machine
                #$global:DSCMachineStatus = 1
            }

            DependsOn = '[File]VeeamTempLogsFolder'
        }

        # Install the Veeam Catalog
        Package 'VeeamCatalog' {
            Name      = 'Veeam Backup Catalog'
            Path      = ($node.VeeamImageMounted + '\Catalog\VeeamBackupCatalog64.msi')
            LogPath   = ($VeeamInstallerLogs + '\VeeamCatalog.log')
            ProductId = '621D27B0-4F53-4158-889F-A80F2D4E4D84'
            DependsOn = '[Script]DotNet4.5.2'
        }

        # Copy the SQL installer to $VeeamTempFiles and rename it 'Setup.exe' as this is what the
        # xSQLServer resource looks for.
        $SQLInstallerPath = ($VeeamTempFiles + '\Source\Setup.exe')

        Script 'CopySQLInstaller' {
            GetScript = {
                return @{ Compliance = (Test-Path -Path $using:SQLInstallerPath) }    
            }

            TestScript = {
                Test-Path $using:SQLInstallerPath
            }

            SetScript = {
                New-Item -Path (Split-Path $using:SQLInstallerPath) -ItemType Directory -Force

                Copy-Item -Path ($using:node.VeeamImageMounted + '\Redistr\x64\SQLEXPR_x64_ENU.exe') `
                          -Destination $using:SQLInstallerPath -Force
            }

            DependsOn = '[Package]VeeamCatalog'
        }

        # Install SQL Express
        xSqlServerSetup 'SqlExpressx64' {
            InstanceName        = 'VEEAMSQL2012'
            SourcePath          = $VeeamTempFiles
            UpdateEnabled       = $true
            Features            = "SQLENGINE"
            ForceReboot         = $true
            SecurityMode        = 'SQL'
            SAPwd               = $Credential
            SetupCredential     = $Credential
            # SQLSysAdminAccounts = 'BUILTIN\Administrators' - Not possible with SQL Express
            DependsOn           = '[Script]CopySQLInstaller'
        }

        # Install other prerequisites as per documentation
        Package 'MicrosoftVisualC2010' {
            Name      = 'Microsoft Visual C++ 2010  x64 Redistributable - 10.0.40219'
            Path      = ($node.VeeamImageMounted + '\Redistr\x64\vcredist100_x64.exe')
            #LogPath  = ($VeeamInstallerLogs + '\MicrosoftVisualC2010.log')
            Arguments = ("/q /log $VeeamInstallerLogs\MicrosoftVisualC2010.log /noreboot")
            ProductId = '1D8E6291-B0D5-35EC-8441-6616F567A0F7'
            DependsOn = '[xSqlServerSetup]SqlExpressx64'
        }

        Package 'SQL2012SystemCLRTypes' {
            Name      = 'Microsoft System CLR Types for SQL Server 2012 (x64)'
            Path      = ($node.VeeamImageMounted + '\Redistr\x64\SQLSysClrTypes.msi')
            LogPath   = ($VeeamInstallerLogs + '\SQLSysClrTypes.log')
            ProductId = 'F1949145-EB64-4DE7-9D81-E6D27937146C'
            DependsOn = '[Package]MicrosoftVisualC2010'
        }

        Package 'SQL2012ManagementObjects' {
            Name      = 'Microsoft SQL Server 2012 Management Objects  (x64)'
            Path      = ($node.VeeamImageMounted + '\Redistr\x64\SharedManagementObjects.msi')
            LogPath   = ($VeeamInstallerLogs + '\SharedManagementObjects.log')
            ProductId = 'FA0A244E-F3C2-4589-B42A-3D522DE79A42'
            DependsOn = '[Package]SQL2012SystemCLRTypes'
        }
        
        # Install the actual Veeam Backup & Replication server        
        Package 'VeeamServer' {
            Name                 = 'Veeam Backup & Replication Server'
            Path                 = ($node.VeeamImageMounted + '\Backup\Server.x64.msi')
            LogPath              = ($VeeamInstallerLogs + '\VeeamServer.log')
            Arguments            = ("VBR_SQLSERVER_AUTHENTICATION='1' " + `
                                    "VBR_SQLSERVER_USERNAME='sa' " + `
                                    "VBR_SQLSERVER_PASSWORD='{0}' " + `
                                    'ACCEPTEULA="yes"' -f $Credential.GetNetworkCredential().Password)
            #PsDscRunAsCredential = $Credential
            #Credential           = $Credential
            ProductId            = '34AD3199-9693-49D6-9197-AEA759082EC2'
            DependsOn            = '[Package]VeeamCatalog',
                                   '[xSqlServerSetup]SqlExpressx64',
                                   '[Package]MicrosoftVisualC2010',
                                   '[Package]SQL2012SystemCLRTypes',
                                   '[Package]SQL2012ManagementObjects'
        }

        # Install the management console
        Package 'VeeamConsole' {
            Name      = 'Veeam Backup & Replication Console'
            Path      = ($node.VeeamImageMounted + '\Backup\Shell.x64.msi')
            LogPath   = ($VeeamInstallerLogs + '\VeeamConsole.log')
            Arguments = 'ACCEPTEULA="YES"'
            ProductId = '789624CC-2499-4BB2-85DF-66EC63202056'
            DependsOn = '[Package]VeeamServer'
        }

    }
    
}

# Look for Data.psd1 in same folder that this has been run from
$ConfigData = "$(Split-Path $MyInvocation.MyCommand.Path)\Data.psd1"
$Credential = New-Object PSCredential -ArgumentList ('Administrator', ('Password1' | ConvertTo-SecureString -AsPlainText -Force))

Write-Host 'Generating MOFs for VM(s)' -ForegroundColor Green
VeeamServer -ConfigurationData $ConfigData `
            -OutputPath 'C:\Lability\Configurations' `
            -Credential $Credential

# Lability related
Test-LabConfiguration -ConfigurationData $ConfigData -Verbose

Start-LabConfiguration -ConfigurationData $ConfigData -Credential $Credential -IgnorePendingReboot -Verbose 

Start-Lab -ConfigurationData $ConfigData -Verbose