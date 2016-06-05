$ErrorActionPreference = 'Stop'

$NewMedia = @(    
    <#
        Windows 10 Pro (VLSC) media
    #>
    @{
        ID              = 'WIN10_x64_Pro_EN_VLSC'
        Filename        = 'SW_DVD5_Win_Pro_10_1511.1_64BIT_English_MLF_X20-93914.ISO'
        Description     = 'Windows 10 64bit Professional English (From VLSC)'
        Architecture    = 'x64'
        MediaType       = 'ISO'
        Uri             = 'C:\Lability\ISOs\SW_DVD5_Win_Pro_10_1511.1_64BIT_English_MLF_X20-93914.ISO'
        ImageName       = 'Windows 10 Pro'
            # The image name inside the 'install.wim' file. Use Get-WindowsImage to find.
        OperatingSystem = 'Windows' 
        CustomData      = @{
            WindowsOptionalFeature = 'NetFx3'
            CustomBootstrap = @"
## Unattend.xml will set the Administrator password, but it won't enable the account on client OSes
NET USER Administrator /active:yes
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
## Kick-start PowerShell remoting on clients to permit applying DSC configurations
Enable-PSRemoting -SkipNetworkProfileCheck -Force
"@
        }
    }

    <#
        Windows 7 Pro (VLSC) media
        
        NOTE: Because Lability relies on DSC, the Windows 7 media will require WMF4.0+ to be
              installed before the DSC portion will work. This means seting up a Windows 7 VM,
              installing the relevant WMF and sysprepping it, so we can re-use the VHD.
    #>
    @{
        Id           = 'WIN7_Pro_EN_VLS'
        Filename     = "SW_D.vhdx"
        Description  = 'Windows 7 Enterprise 64bit English Evaluation - Patched 02/16'
        Architecture = 'x64' 
        MediaType    = 'VHD' 
        Uri          = "C:\Lability\MasterVirtualHardDisks\$Name.vhdx"
        CustomData = @{
            PartitionStyle = 'MBR'
            CustomBootstrap = @"
## Unattend.xml will set the Administrator password, but it wont enable the account on client OSes
NET USER Administrator /active:yes
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
## Kick-start PowerShell remoting on clients to permit applying DSC configurations
Enable-PSRemoting -SkipNetworkProfileCheck -Force
"@
        }
    }
    #>

    <#
        Ubuntu Server 16.04
        NOTE: This is a VHD from an Ubuntu VM that I have already created and set up.
              The automation portion of lability is very limited when dealing with non-Windows
              OSes as it is designed primarily for Windows VMs (Using DSC and unattend.xml files)
              
              I primarily use this with `New-LabVM -MediaID Ubuntu_Server_16.04_amd64 -Name 'My New Ubuntu VM'`
              for spinning up a single quick Ubuntu VM
    #>
    @{
        ID              = 'Ubuntu_Server_16.04_amd64'
        Filename        = 'Ubuntu Server 16.04.vhdx'
        Description     = 'Ubuntu Server 16.04 LTS'
        Architecture    = 'x64'
        MediaType       = 'vhd'
        Uri             = 'C:\Hyper-V\VMs\Ubuntu Server Template\VHDs\Ubuntu Server Template.vhdx'
        OperatingSystem = 'Linux' 
        CustomData      = @{
            WindowsOptionalFeature = ''
            CustomBootstrap = @"
"@
        }
    }


)

# Add each new media item
$NewMedia.ForEach({
    if (!(Test-LabMedia $_)) {
        Register-LabMedia @_ -Force
    }
})