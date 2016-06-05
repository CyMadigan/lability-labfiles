@{
    AllNodes = @(
        # All nodes
        @{
            NodeName                    = '*'
            Lability_SwitchName         = 'LAB-External'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }

        # VEEAM
        @{
            NodeName                    = 'VEEAM01'
            Role                        = 'veeam'
                                        
            Lability_Resource           = @('VeeamBackupAndReplication')
            VeeamImageMounted           = 'C:\Resources\VeeamBackupAndReplication'
            <#
            VeeamImageFile              = 'C:\Resources\VeeamBackup&Replication_9.0.0.902.iso'
            VeeamImageMounted           = 'V:'
            #>
        }
    ) # allnodes

     NonNodeData = @{
        Lability = @{
            EnvironmentPrefix           = 'LAB-'

            Network = @(
                @{
                    Name                = 'LAB-External'
                    Type                = 'External'
                    NetadapterName      = 'Wi-Fi'
                    AllowManagementOS   = $true
                }
            )

            DSCResource = @(
                @{ Name = 'xComputerManagement' }
                @{ Name = 'PSDesiredStateConfiguration' }
                @{ Name = 'xSQLServer' }
                @{ Name = 'xStorage' }
            )

            Resource = @(
                @{
                    Id                  = 'VeeamBackupAndReplication'
                    DestinationPath     = '\Resources\VeeamBackupAndReplication'
                    Filename            = 'VeeamBackup&Replication_9.0.0.902.iso'
                    #Uri                 = 'file://C:\Lability\Resources\Veeam Backup and Replication\VeeamBackup&Replication_9.0.0.902.iso'
                    Checksum            = ''
                    Expand              = $true
                }
            )
            
        }
    } # nonnodedata

}