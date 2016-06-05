@{
    AllNodes = @(
        # All nodes
        @{
            NodeName                    = '*'
            Lability_SwitchName         = 'LAB-External'
            PSDscAllowPlainTextPassword = $true
            PSDscAllowDomainUser        = $true
        }

        # ADK
        @{
            NodeName                    = 'ADK01'
            Role                        = 'adk'
                                        
            Lability_Resource           = @('ADK2012R2')
                        ADKTempFolder               = 'C:\ADKTemp'
        }
    ) # allnodes

     NonNodeData = @{
        Lability = @{
            EnvironmentPrefix           = 'LAB-'

            Network = @(
                @{
                    Name                = 'LAB-External'
                    Type                = 'External'
                    NetadapterName      = 'Ethernet'
                    AllowManagementOS   = $true
                }
            )

            DSCResource = @(
                @{ Name = 'PSDesiredStateConfiguration' }
            )

            Resource = @(
                @{
                    Id                  = 'ADK2012R2'
                    DestinationPath     = '\adktemp\offline-files'
                    Filename            = 'adkofflinefiles2012R2.zip'
                    Checksum            = ''
                    Expand              = $true
                }
            )
            
        }
    } # nonnodedata

}