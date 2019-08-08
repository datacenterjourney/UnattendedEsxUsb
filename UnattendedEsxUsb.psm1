#########################################################

function New-KsConfig {
    <#
        .SYNOPSIS
            Creates the information for kickstart script
        .DESCRIPTION
            Builds all of the information needed to create a kickstart
            script for an unattended ESX usb installation.
        .EXAMPLE
            New-KsConfig -passwd P@ssw0rd! -hostname MP-TST01 -vlanId 1919 -ipAddr 192.168.19.19 -subnet 255.255.255.0 -gateway 192.168.19.1 -dns1 192.168.19.5 -dns2 8.8.8.8 -firstNic vmnic0 -secondNic vmnic1
            This will create the kickstart configuration file information and
            will print the information to the screen to be reviewed and or copied.
        .EXAMPLE
            $KsConfig = New-KsConfig -passwd P@ssw0rd! -hostname MP-TST01 -vlanId 1919 -ipAddr 192.168.19.19 -subnet 255.255.255.0 -gateway 192.168.19.1 -dns1 192.168.19.5 -dns2 8.8.8.8 -firstNic vmnic0 -secondNic vmnic1
            This will create the kickstart configuration file information and
            save it to a local variable. That variable information can then be
            passed on to a command to create a file with the information.
        .NOTES
            Created: 07/15/2019 by Manuel Martinez, Version 1.0
            Github: https://www.github.com/manuelmartinez-it
    #>
    [CmdletBinding()]
    param (
        # Password to set on ESXi host
        [Parameter(Mandatory)]
        [string]
        $passwd,

        # Hostname to set on ESXi host
        [Parameter(Mandatory)]
        [string]
        $hostname,

        # VLAN ID used for ESXi management
        [Parameter(Mandatory)]
        [string]
        $vlanId,

        # IP Address to assign to ESXi host
        [Parameter(Mandatory)]
        [string]
        $ipAddr,

        # Subnet to assign to management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $subnet,

        # Default gateway for management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $gateway,

        # First DNS address for management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $dns1,

        # Second DNS address for management IP of ESXi host
        [Parameter(Mandatory = $false)]
        [string]
        $dns2,

        # First nic to add for management
        [Parameter(Mandatory)]
        [string]
        $firstNic,

        # Second nic to add for management
        [Parameter(Mandatory = $false)]
        [string]
        $secondNic
    )

    $lmPasswd = 'MonLog19!'

    if ($secondNic -and $dns2) {
        $ksCfg = "
        ## ESXi Unattended Installation Script
        ## Author: Manuel A. Martinez
        ## Date 07-15-2019
        ## Credits: M. Buijs

        # Stage 01 - Pre-Installation

        # Accept the VMware End User License Agreement
        vmaccepteula

        # Set the root password
        rootpw $passwd

        # The installation media
        install --firstdisk=usb --overwritevmfs

        # Reboot the ESXi host
        reboot

        ### Set the network information on the first external MP network adapter
        network --bootproto=static --device=$firstNic --hostname=$hostname --vlanid=$vlanId --ip=$ipAddr --netmask=$subnet --gateway=$gateway --nameserver=$dns1,$dns2 --addvmportgroup=0

        # Stage 01 - Complete

        # Stage 02 - Prompt for host information

        %firstboot --interpreter=busybox

        # Add NTP Server addresses
        echo 'server 0.pool.ntp.org' >> /etc/ntp.conf;
        echo 'server 1.pool.ntp.org' >> /etc/ntp.conf;

        # Allow NTP through firewall
        esxcfg-firewall -e ntpClient

        # Enable NTP autostartup
        /sbin/chkconfig ntpd on;

        # Rename local datastore
        vim-cmd hostsvc/datastore/rename datastore1 Local-$hostname

        # Enable second management nic
        esxcli network vswitch standard uplink add --uplink-name=$secondNic --vswitch-name=vSwitch0

        # Configure SCAv2 on the host
        esxcli system settings kernel set -s 'hyperthreadingMitigation' -v 'TRUE'

        # Create local user for monitoring
        esxcli system account add -i logicmonitor -p $lmPasswd -c $lmPasswd -d 'ReadOnly account for LogicMonitor'

        # Set the local monitoring permissions to 'ReadOnly'
        esxcli system permission set -i logicmonitor -r ReadOnly

        # Disable CEIP
        esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 1

        # Create a new local user
        # esxcli system account add 
        # https://pubs.vmware.com/vsphere-6-5/index.jsp?topic=%2Fcom.vmware.vcli.examples.doc%2FGUID-3C1F3933-E86C-478F-80F7-EC8AE1105CF2.html

        # Enable maintaince mode
        esxcli system maintenanceMode set -e true

        # Reboot
        esxcli system shutdown reboot -d 15 -r 'Rebooting after ESXi host configuration'

        # Stage 02 - Complete
        "        
    }
    elseif ($EsxSecondNic -and !$EsxDns2) {
        $ksCfg = "
        ## ESXi Unattended Installation Script
        ## Author: Manuel A. Martinez
        ## Date 07-15-2019
        ## Credits: M. Buijs

        # Stage 01 - Pre-Installation

        # Accept the VMware End User License Agreement
        vmaccepteula

        # Set the root password
        rootpw $passwd

        # The installation media
        install --firstdisk=usb --overwritevmfs

        # Reboot the ESXi host
        reboot

        ### Set the network information on the first external MP network adapter
        network --bootproto=static --device=$firstNic --hostname=$hostname --vlanid=$vlanId --ip=$ipAddr --netmask=$subnet --gateway=$gateway --nameserver=$dns1 --addvmportgroup=0

        # Stage 01 - Complete

        # Stage 02 - Prompt for host information

        %firstboot --interpreter=busybox

        # Add NTP Server addresses
        echo 'server 0.pool.ntp.org' >> /etc/ntp.conf;
        echo 'server 1.pool.ntp.org' >> /etc/ntp.conf;

        # Allow NTP through firewall
        esxcfg-firewall -e ntpClient

        # Enable NTP autostartup
        /sbin/chkconfig ntpd on;

        # Rename local datastore
        vim-cmd hostsvc/datastore/rename datastore1 Local-$hostname

        # Enable second management nic
        esxcli network vswitch standard uplink add --uplink-name=$secondNic --vswitch-name=vSwitch0

        # Configure SCAv2 on the host
        esxcli system settings kernel set -s 'hyperthreadingMitigation' -v 'TRUE'

        # Create local user for monitoring
        esxcli system account add -i logicmonitor -p $lmPasswd -c $lmPasswd -d 'ReadOnly account for LogicMonitor'

        # Set the local monitoring permissions to 'ReadOnly'
        esxcli system permission set -i logicmonitor -r ReadOnly
                
        ### Disable CEIP
        esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 1

        ### Enable maintaince mode
        esxcli system maintenanceMode set -e true

        ### Reboot
        esxcli system shutdown reboot -d 15 -r 'Rebooting after ESXi host configuration'

        # Stage 02 - Complete
        "          
    } 
    elseif (!$EsxSecondNic -and $EsxDns2) {
        $ksCfg = "
        ## ESXi Unattended Installation Script
        ## Author: Manuel A. Martinez
        ## Date 07-15-2019
        ## Credits: M. Buijs

        # Stage 01 - Pre-Installation

        # Accept the VMware End User License Agreement
        vmaccepteula

        # Set the root password
        rootpw $passwd

        # The installation media
        install --firstdisk=usb --overwritevmfs

        # Reboot the ESXi host
        reboot

        ### Set the network information on the first external MP network adapter
        network --bootproto=static --device=$firstNic --hostname=$hostname --vlanid=$vlanId --ip=$ipAddr --netmask=$subnet --gateway=$gateway --nameserver=$dns1,$dns2 --addvmportgroup=0

        # Stage 01 - Complete

        # Stage 02 - Prompt for host information

        %firstboot --interpreter=busybox

        # Add NTP Server addresses
        echo 'server 0.pool.ntp.org' >> /etc/ntp.conf;
        echo 'server 1.pool.ntp.org' >> /etc/ntp.conf;

        # Allow NTP through firewall
        esxcfg-firewall -e ntpClient

        # Enable NTP autostartup
        /sbin/chkconfig ntpd on;

        # Rename local datastore
        vim-cmd hostsvc/datastore/rename datastore1 Local-$hostname

        # Configure SCAv2 on the host
        esxcli system settings kernel set -s 'hyperthreadingMitigation' -v 'TRUE'

        # Create local user for monitoring
        esxcli system account add -i logicmonitor -p $lmPasswd -c $lmPasswd -d 'ReadOnly account for LogicMonitor'

        # Set the local monitoring permissions to 'ReadOnly'
        esxcli system permission set -i logicmonitor -r ReadOnly
        
        ### Disable CEIP
        esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 1

        ### Enable maintaince mode
        esxcli system maintenanceMode set -e true

        ### Reboot
        esxcli system shutdown reboot -d 15 -r 'Rebooting after ESXi host configuration'

        # Stage 02 - Complete
        "  
    }
    elseif (!$EsxSecondNic -and !$EsxDns2) {
        $ksCfg = "
        ## ESXi Unattended Installation Script
        ## Author: Manuel A. Martinez
        ## Date 07-15-2019
        ## Credits: M. Buijs

        # Stage 01 - Pre-Installation

        # Accept the VMware End User License Agreement
        vmaccepteula

        # Set the root password
        rootpw $passwd

        # The installation media
        install --firstdisk=usb --overwritevmfs

        # Reboot the ESXi host
        reboot

        ### Set the network information on the first external MP network adapter
        network --bootproto=static --device=$firstNic --hostname=$hostname --vlanid=$vlanId --ip=$ipAddr --netmask=$subnet --gateway=$gateway --nameserver=$dns1 --addvmportgroup=0

        # Stage 01 - Complete

        # Stage 02 - Prompt for host information

        %firstboot --interpreter=busybox

        # Add NTP Server addresses
        echo 'server 0.pool.ntp.org' >> /etc/ntp.conf;
        echo 'server 1.pool.ntp.org' >> /etc/ntp.conf;

        # Allow NTP through firewall
        esxcfg-firewall -e ntpClient

        # Enable NTP autostartup
        /sbin/chkconfig ntpd on;

        # Rename local datastore
        vim-cmd hostsvc/datastore/rename datastore1 Local-$hostname

        # Configure SCAv2 on the host
        esxcli system settings kernel set -s 'hyperthreadingMitigation' -v 'TRUE'

        # Create local user for monitoring
        esxcli system account add -i logicmonitor -p $lmPasswd -c $lmPasswd -d 'ReadOnly account for LogicMonitor'

        # Set the local monitoring permissions to 'ReadOnly'
        esxcli system permission set -i logicmonitor -r ReadOnly

        ### Disable CEIP
        esxcli system settings advanced set -o /UserVars/HostClientCEIPOptIn -i 1

        ### Enable maintaince mode
        esxcli system maintenanceMode set -e true

        ### Reboot
        esxcli system shutdown reboot -d 15 -r 'Rebooting after ESXi host configuration'

        # Stage 02 - Complete
        "          
    }

    return $ksCfg
    
}

#########################################################

function Get-IndicesOf {
    <#
        .SYNOPSIS
            Searches and array and returns the indices
        .DESCRIPTION
            Searches through an array and returns the indices of the search string provided and returns the index value
        .EXAMPLE
            Get-IndicesOf -Array $MyList -Value 'Find This'
        .NOTES
            Created: 07/15/2019 by Manuel Martinez, Version 1.0
            Github: https://www.github.com/manuelmartinez-it
    #>

    [CmdletBinding()]
    param (
        # Array to search through for indices
        [Parameter(Mandatory)]
        [array]
        $Array,

        # String value to search for in array
        [Parameter(Mandatory)]
        [string]
        $Value
    )
    $i = 0
    foreach ($el in $Array) { 
        if ($el -match $Value) { $i } 
        ++$i
    }
    
    # return $i
}

#########################################################

function Find-EsxUsb {
    <#
        .SYNOPSIS
            Searches for attached USB drives and returns the disk & identifier info from diskutil
    #>   
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        # Get the all of the USB information
        $usbDisks = Get-DiskUtilDisk -DiskString 'external, physical'
        $usbIds = Get-DiskUtilIdentifier -DiskIdString 'NO NAME'

        # Check to make sure that the USBs are all new and formated correctly and then put into an array
        if ($usbDisks.Count -ne $usbIds.Count) {
            Write-Error -Message "One of the USB drives is not a new SanDisk and needs to be labeled 'NO NAME' to proceed"
            break
        }
        elseif ($usbDisks.GetType().Name -eq "String") {
            $esxUsbDisks = @(
                [PSCustomObject]@{Disk = $usbDisks; Identifier = $usbIds }
            )
        }
        else {
            $esxUsbDisks = @(
                for ($i = 0; $i -lt $usbDisks.Count; $i++) {
                    [PSCustomObject]@{Disk = $usbDisks[$i]; Identifier = $usbIds[$i] }
                }
            )
        }

        return $esxUsbDisks
    }

}

#########################################################

function Format-EsxUsb {
    <#
        .SYNOPSIS
            Formats USB drive to appropriate name for approve ESXi version
    #>

    [CmdletBinding()]
    param (
        # Version of ESXi to format USB drive
        [Parameter(
            Mandatory = $false
        )]
        [string]
        $EsxVersion
    )
    
    begin {
        Read-MsOsType
    }
    
    process {

        if ($EsxVersion) {
            switch ($EsxVersion) {
                # $EsxIsoInfo = Find-EsxIso
                "6.7.0U2a" {
                    $getVersion = Get-EsxIsoVersion $EsxVersion
                    $newUsbName = $getVersion[1]
                }
                "6.5.0U1" {
                    $getVersion = Get-EsxIsoVersion $EsxVersion
                    $newUsbName = $getVersion[1]
                }
                Default {
                    $newUsbName = "Error"
                    Write-Error -Message "An approved version was not selected [6.7.0U2a, 6.5.0u1]"
                    break
                }
            }
        } else {
            # Prompt for version of ESXi Installer to create
            $getVersion = Get-EsxIsoVersion
            $newUsbName = $getVersion[1]
        }

        # Verifies to make sure there is an ISO mounted


        # Verifies to make sure there is proper formated USB drive mounted
        if ($newUsbName -eq "Error") {
            break
        }

        if (!$getVersion) {
            Write-Error -Message "An appropriate ISO is not mounted"
            break
        }

        # Get the sudo password for currently logged on user
        # Get-SudoPw | Out-Null
        Start-Sleep -Seconds 1
        
        Write-Host -Object "Starting the format of the ESXi USB unattended installation drive" -ForegroundColor Blue

        # Gets the ESXi Volume Name, USB Drive & USB Identifier
        # $volumeEsxIso = $esxIso[0]
        
        $usbDisk = Get-DiskUtilDisk -DiskString 'external, physical'
        $usbId = Get-DiskUtilIdentifier -DiskIdString 'NO NAME'

        # if (!$usbId) {
        #     Write-Error "There is no blank USB found with the label: 'NO NAME'"
        #     break
        # }

        # Format the previous found USB drive
        diskutil eraseDisk FAT32 $newUsbName MBRFormat $usbDisk | Out-Null

        # Unmount the USB drive
        diskutil unmount $usbId | Out-Null

        # Start up the command-line partitioner 'fdisk' in interactive mode: 
        # flag first partition as active and bootable, write the changes, and exit fdisk
        # 'f 1' | sudo fdisk -e /dev/$usbDisk | Out-Null
        # 'write' | sudo fdisk -e /dev/$usbDisk | Out-Null
        # 'quit' | sudo fdisk -e /dev/$usbDisk | Out-Null
        Write-Output "f 1\nwrite\nquit" | sudo fdisk -e /dev/$usbDisk | Out-Null
        Write-Host -Object "Ignore fdisk errors above there is no way to prevent these messages" -ForegroundColor Yellow

        # Mount the usb disk after setting the partition as active
        diskutil mount /dev/$usbId | Out-Null

        return $getVersion
    }
    
}

#########################################################

function Read-MsOsType {
    <#
        .SYNOPSIS
            Checks to make sure that the version of PowerShell core running is for MacOS
    #>

    process {
        if ($IsMacOs) {
        }
        else {
            Write-Error -Message "This will only run on PowerShell Core on MacOS"
            break
        }
    }
}

#########################################################

function Get-SudoPw {
    <#
        .SYNOPSIS
            Gets the currently logged on user and prompts for the password to be able to run sudo commands
    #>    
    begin {
        Read-MsOsType
    }
    
    process {
        $currentUser = id -un
        $sudoCreds = Get-Credential -message 'Enter ''sudo'' Password' -username $currentUser
        $sudoCreds.GetNetworkCredential().password | sudo -U $sudoCreds.username -l -S | Out-Null
        return $sudoCreds
    }
}

#########################################################

function Find-EsxIso {
    <#
        .SYNOPSIS
            Searches through diskutil for any mounted ESXi ISOs
    #>    
    [CmdletBinding()]
    param (
        # Specified version of ESX
        [Parameter( Mandatory = $false)]
        [string]
        $SelectedVer
    )
        
    begin {
        Read-MsOsType

        $isoVolumes = diskutil list
        $isosMounted = Get-IndicesOf -Array $isoVolumes -Value 'disk image'
        
        $MountedEsxIsos = New-Object System.Collections.ArrayList


    }
    
    process {
        if ($null -eq $isosMounted) {
            Write-Error -Message "Could not find any ESXi ISOs mounted"
            break
        }

        if ($isosMounted.Count -gt 1) {
            foreach ($isoMount in $isosMounted) {
                $esxIso = $isoVolumes[$isoMount]
                $usbIdName = [string]$esxIso
                $diskId = $usbIdName.Substring(0, $usbIdName.IndexOf(' '))
                $diskIdLabel = diskutil info $diskId
                $fullIsoId = $diskIdLabel[6]
                $fullIsoName = $fullIsoId.Split(" ")[$($fullIsoId.Split(" ").Count - 1)]
                if ($fullIsoName -match 'ESX') {
                    $MountedEsxIsos.Add($fullIsoName) | Out-Null
                }
                
            }
        } else {
            $esxIso = $isoVolumes[$isosMounted]
            $usbIdName = [string]$esxIso
            $diskId = $usbIdName.Substring(0, $usbIdName.IndexOf(' '))
            $diskIdLabel = diskutil info $diskId
            $fullIsoId = $diskIdLabel[6]
            $fullIsoName = $fullIsoId.Split(" ")[$($fullIsoId.Split(" ").Count - 1)]
            if ($fullIsoName -match 'ESX') {
                $MountedEsxIsos.Add($fullIsoName) | Out-Null
            }
        }

        if (!$MountedEsxIsos) {
            Write-Error -Message "Could not find any ESXi ISOs mounted"
            break
        }
        
        return $MountedEsxIsos

    }   
}

#########################################################

function Get-EsxIsoVersion {    
    <#
        .SYNOPSIS
            Lists the currently mounted ESXi ISOs and prompts for a selection
    #>

    [CmdletBinding()]
    param (
        # Version of ESXi to format USB drive
        [Parameter(Mandatory = $false)]
        [string]
        $EsxIsoVer
    )

    begin {
        Read-MsOsType
    }
    
    process {
        if ($EsxIsoVer) {
            $isoSelected = $EsxIsoVer
            $esxIsosFullName = Find-EsxIso

            # if (!$esxIsosFullName) {
            #     Write-Error -Message "You either don't have an ESXi ISO currently mounted or it's not an approved version"
            #     break
            # }

            switch ($isoSelected) {
                "6.7.0U2a" {
                    $isoFormat = "ESXI-6.7.0-20190402001-STANDARD" 
                    $usbIsoFormat = "ESX67U2A"
                }
                "6.5.0U1" {
                    $isoFormat = "ESXI-6.5.0-20170702001-STANDARD" 
                    $usbIsoFormat = "ESX65U1"
                }
                Default {
                    Write-Error -Message "An approved version was not selected [6.7.0U2a, 6.5.0u1]"
                    break
                }
            }
   
        }else {
            $esxIsosFullName = Find-EsxIso
            $esxIsoVersions = New-Object System.Collections.ArrayList
            Write-Host -Object "`nYou have the following ESXi ISOs mounted:" -ForegroundColor DarkCyan

            foreach ($esxIsoName in $esxIsosFullName) { 
                switch ($esxIsoName) {
                    "ESXI-6.7.0-20190402001-STANDARD" {
                        Write-Host -Object "6.7.0U2a" -ForegroundColor DarkCyan 
                        $esxiVersion = '6.7.0U2a'
                    }
                    "ESXI-6.5.0-20170702001-STANDARD" {
                        Write-Host -Object "6.5.0U1" -ForegroundColor DarkCyan 
                        $esxiVersion = '6.5.0U1'
                    }
                    Default { 
                        Write-Host -Object "You either don't have an ESXi ISO currently mounted or it's not an approved version" -ForegroundColor Yellow 
                    }
                }
                $esxIsoVersions.Add($esxiVersion) | Out-Null
            }

            if (!$esxIsosFullName) {
                Write-Error -Message "You either don't have an ESXi ISO currently mounted or it's not an approved version"
                break
            }

            $isoIndex = $esxIsoVersions.Count
            if ($isoIndex -gt 1) {
                Write-Host -Object "Which version of ESXi do you want to use: " -NoNewline -ForegroundColor Yellow
                $isoSelected = Read-Host
            }    else {
                $isoSelected = $esxIsoVersions
            }
                switch ($isoSelected) {
                    "6.7.0U2a" {
                        $isoFormat = "ESXI-6.7.0-20190402001-STANDARD" 
                        $usbIsoFormat = "ESX67U2A"
                    }
                    "6.5.0U1" {
                        $isoFormat = "ESXI-6.5.0-20170702001-STANDARD" 
                        $usbIsoFormat = "ESX65U1"
                    }
                    Default {
                        Write-Host -Object "You didn't make a valid selection, try again" -ForegroundColor Red
                        Get-EsxIsoVersion
                    }
                }

        }
        $IsoInfo = New-Object System.Collections.ArrayList
        $IsoInfo.Add($isoFormat) | Out-Null
        $IsoInfo.Add($usbIsoFormat) | Out-Null
        return $IsoInfo
    }
}

#########################################################

function Set-BootCfg {
    [CmdletBinding()]
    param (
        # Name of formatted USB drive
        [Parameter(Mandatory = $true)]
        [string]
        $UsbName
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        switch ($UsbName) {
            "ESX65U1" { 
                $replace1_1 = 'timeout=5'
                $replace1_2 = 'timeout=0'
                $replace2_1 = 'runweasel'
                $replace2_2 = 'ks=usb:/ks.cfg'
                $replace3_1 = 'Loading ESXi installer'
                $replace3_2 = 'MacStadium Unattended ESXi Installer"'
            }
            "ESX67U2A" {
                $replace1_1 = 'timeout=5'
                $replace1_2 = 'timeout=0'
                $replace2_1 = 'cdromBoot runweasel'
                $replace2_2 = 'ks=usb:/ks.cfg'
                $replace3_1 = 'Loading ESXi installer'
                $replace3_2 = 'MacStadium Unattended ESXi Installer'
            }
            Default {

            }
        }

        $bootCfgPath1 = "/Volumes/$UsbName/BOOT.CFG"
        $bootCfgPath2 = "/Volumes/$UsbName/EFI/BOOT/BOOT.CFG"
        $cfgPaths = New-Object System.Collections.ArrayList
        $cfgPaths.Add($bootCfgPath1) | Out-Null
        $cfgPaths.Add($bootCfgPath2) | Out-Null

        foreach($path in $cfgPaths){
            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace1_1", "$replace1_2" | Set-Content -Path $path

            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace2_1", "$replace2_2" | Set-Content -Path $path
            
            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace3_1", "$replace3_2" | Set-Content -Path $path
        }
    }
}

#########################################################

function Set-BulkBootCfg {
    [CmdletBinding()]
    param (
        # Name of formatted USB drive
        [Parameter(Mandatory = $true)]
        [string]
        $UsbNames
    )
    
    begin {
        Read-MsOsType
    }
    
    process {

        if ($usbNames -match "ESX65U1") {
            $usbBoot = "ESX65U1"
        }elseif ($usbNames -match "ESX67U2A") {
            $usbBoot = "ESX67U2A"
        }

        switch ($usbBoot) {
            "ESX65U1" { 
                $replace1_1 = 'timeout=5'
                $replace1_2 = 'timeout=0'
                $replace2_1 = 'runweasel'
                $replace2_2 = 'ks=usb:/ks.cfg'
                $replace3_1 = 'Loading ESXi installer'
                $replace3_2 = 'MacStadium Unattended ESXi Installer'
            }
            "ESX67U2A" {
                $replace1_1 = 'timeout=5'
                $replace1_2 = 'timeout=0'
                $replace2_1 = 'cdromBoot runweasel'
                $replace2_2 = 'ks=usb:/ks.cfg'
                $replace3_1 = 'Loading ESXi installer'
                $replace3_2 = 'MacStadium Unattended ESXi Installer'
            }
            Default {

            }
        }

        $bootCfgPath1 = "/Volumes/$UsbNames/BOOT.CFG"
        $bootCfgPath2 = "/Volumes/$UsbNames/EFI/BOOT/BOOT.CFG"
        $cfgPaths = New-Object System.Collections.ArrayList
        $cfgPaths.Add($bootCfgPath1) | Out-Null
        $cfgPaths.Add($bootCfgPath2) | Out-Null

        foreach($path in $cfgPaths){
            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace1_1", "$replace1_2" | Set-Content -Path $path

            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace2_1", "$replace2_2" | Set-Content -Path $path
            
            $boot1 = $null
            $boot1 = Get-Content -Path $path -Raw
            $boot1 -replace "$replace3_1", "$replace3_2" | Set-Content -Path $path
        }
    }
}

#########################################################

function Get-DiskUtilDisk {
    [CmdletBinding()]
    param (
        # Value to search for in 'diskutil list'
        [Parameter(Mandatory)]
        [string]
        $DiskString
    )
    
    begin {
        Read-MsOsType
    }

    process {
        # Get list of all attached disks with diskutil
        $diskUtilArray = diskutil list

        # Searches the array and gets the index of the USB drive and disk name
        $diskUtilDiskSearch = Get-IndicesOf -Array $diskUtilArray -Value $diskString
        if (!$diskUtilDiskSearch) {
            Write-Error -Message "Could not find drive with the label $diskString"
            break
        }

        # Uses the index number to return disk number of previous search and adds to array
        $diskUtilReturnArray = New-Object System.Collections.ArrayList

        if ($diskUtilDiskSearch.Count -gt 1) {
            # Write-Host -Object "There are lots of disks" -ForegroundColor Magenta
            foreach ($diskUtilReturn in $diskUtilDiskSearch) {
                $diskUtilReturnName = $diskUtilArray[$diskUtilReturn]
                $diskUtilReturnNum = $diskUtilReturnName.Substring(0, $diskUtilReturnName.IndexOf(' '))
                $diskUtilReturnArray.Add($diskUtilReturnNum) | Out-Null
            }
        } else {
            # Write-Host -Object "There is only 1 disk" -ForegroundColor DarkMagenta
            $diskUtilReturnName = $diskUtilArray[$diskUtilDiskSearch]
            $diskUtilReturnNum = $diskUtilReturnName.Substring(0, $diskUtilReturnName.IndexOf(' '))
            $diskUtilReturnArray.Add($diskUtilReturnNum) | Out-Null
            }
        
        return $diskUtilReturnArray
    }
}

#########################################################

function Get-DiskUtilIdentifier {
    [CmdletBinding()]
    param (
        # Name to search for in 'diskutil list' to get identifier
        [Parameter(Mandatory)]
        [string]
        $DiskIdString
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        # Get list of all attached disks with diskutil
        $diskUtilIdArray = diskutil list

        # Searches the array and gets the index of the USB drive and disk name
        $diskUtilIdSearch = Get-IndicesOf -Array $diskUtilIdArray -Value $DiskIdString
        if (!$diskUtilIdSearch) {
            Write-Error -Message "Could not find drive with the label $DiskIdString"
            break
        }

        # Uses the index number to return disk number of previous search and adds to array
        $diskUtilIdReturnArray = New-Object System.Collections.ArrayList

        if ($diskUtilIdSearch.Count -gt 1) {
            foreach ($diskUtilIdReturn in $diskUtilIdSearch) {
                $usbDisk = $diskUtilIdArray[$diskUtilIdReturn]
                $usbIdName = [string]$usbDisk
                $usbIdNum = $usbIdName.Split(" ")[$($usbIdName.Split(" ").Count - 1)]
                $diskUtilIdReturnArray.Add($usbIdNum) | Out-Null
            }
        } else {
            $usbDisk = $diskUtilIdArray[$diskUtilIdSearch]
            $usbIdName = [string]$usbDisk
            $usbIdNum = $usbIdName.Split(" ")[$($usbIdName.Split(" ").Count - 1)]
            $diskUtilIdReturnArray.Add($usbIdNum) | Out-Null
        }
        return $diskUtilIdReturnArray        
    }
}

#########################################################

function Get-UsbResponse {
    [CmdletBinding()]
    param (
        
    )
    
    begin {
        Write-Host -Object "This batch is complete are you ready to continue? [Yes or Stop] " -NoNewline -ForegroundColor Yellow
        $continueResponse = Read-Host
    }
    
    process {
        switch ($continueResponse) {
            'yes' {
                Start-Sleep -Milliseconds 250
            }
            'stop' { 
                break
            }
            Default {
                Write-Host -Object "You didn't make a proper selection. Please type 'Yes' or 'Stop'" -ForegroundColor Red
                Get-UsbResponse
            }
        }
    }

}

#########################################################

function Reset-EsxUsb {
    <#
        .SYNOPSIS
            Formats USB drive on MacOS.
        .DESCRIPTION
            This will look for an external drive and format it.
        .EXAMPLE
            Reset-EsxUsb
        .NOTES
            Created: 07/17/2019 by Manuel Martinez, Version 1.0
            Github: https://www.github.com/manuelmartinez-it
            Credits: Madeline Berry - Suggested creating this command
            in order to avoid having to manually search and format the
            USB drive to the proper label.
    #>
    [CmdletBinding()]
    param (
        <#
        # Specify USB disk to reset
        [Parameter()]
        [string]
        $usbDriveSelected
        #>
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        # Get list of all attached disks with diskutil
        $diskUtilList = diskutil list

        # Searches the array and gets the index of the USB drive and disk name
        $externalUsb = Get-IndicesOf -Array $diskUtilList -Value '(external, physical)'
        if (!$externalUsb) {
            Write-Error -Message "Could not find USB drive of type (external, physical)"
            break
        }
        $externalUsbDrive = $diskUtilList[$externalUsb]
        $usbDriveNum = $externalUsbDrive.Substring(0, $externalUsbDrive.IndexOf(' '))

        # Verify formatting of the previously found USB drive
        diskutil list $usbDriveNum
        Write-Host -ForegroundColor Yellow $usbDriveNum
        Write-Host -ForegroundColor Red "Are you sure you want to format the external drive listed above? [Y or N]: " -NoNewline
        $formatAnswer = Read-Host
        # $formatAnswer

        switch ($formatAnswer) {
            'y' {
                # Format the previously found and confirmed USB drive
                $resetUsbName = 'NO NAME'
                diskutil eraseDisk FAT32 $resetUsbName MBRFormat $usbDriveNum | Out-Null
                Write-Host -ForegroundColor Green "The drive $usbDriveNum was formatted and labeled '$resetUsbName'"
            }
            'n' { 
                diskutil list
                Write-Host -Object "Verify USB drive is listed above and run command again to reset" -ForegroundColor Blue
                break
            }
            Default {
                Write-Host -ForegroundColor Yellow "You didn't make a proper selection. Please type 'Y' or 'N'"
                Reset-EsxUsb
            }
        }
    }
}

#########################################################

function New-EsxUsb {
    <#
        .SYNOPSIS
            Creates new ESXi 6.7U2a USB unattended install disk on MacOS.
        .DESCRIPTION
            Using PowerShell Core on MacOS this will create a ESXi 6.7U2a USB unattended 
            install disk to be used for a single instance. The disk can then be used to 
            boot on a system and it will perform an unattended installation of ESXi on the 
            same USB that was created using this command.
        .EXAMPLE
            New-EsxUsb -EsxPasswd MyP@ssW0rd! -EsxHostname TST-HOST -EsxVlanId 1919 -EsxIpAddr 192.168.19.19 -EsxSubnet 255.255.255.0 -EsxGateway 192.168.19.1 -EsxDns1 192.168.19.5 -EsxDns2 8.8.8.8 -EsxFirstNic vmnic0 -EsxSecondNic vmnic1
            This creates a new ESXi USB installer with two nics active for management and also 
            two different DNS servers. The naming of the nics must vmnicX where X is the number 
            of the installed adapter. For example vmnic0 and vmnic1 would be the firsts two 
            onboard network adapters.
        .EXAMPLE
            New-EsxUsb -EsxPasswd MyP@ssW0rd! -EsxHostname TST-HOST -EsxVlanId 1919 -EsxIpAddr 192.168.19.19 -EsxSubnet 255.255.255.0 -EsxGateway 192.168.19.1 -EsxDns1 192.168.19.5 -EsxFirstNic vmnic2 -EsxSecondNic vmnic3
            This creates a ESXi USB installer with the two nics active for management and only
            one DNS server. The network adapters selected here are for the two external network
            adapters for example on a connected Sonet box.
        .EXAMPLE
            New-EsxUsb -EsxPasswd MyP@ssW0rd! -EsxHostname TST-HOST -EsxVlanId 1919 -EsxIpAddr 192.168.19.19 -EsxSubnet 255.255.255.0 -EsxGateway 192.168.19.1 -EsxDns1 192.168.19.5 -EsxFirstNic vmnic3 -EsxSecondNic vmnic5
            This creates a ESXi USB installer with the two nics active for management and only
            one DNS server. The network adapters selected here are for the two external network
            adapters for example with two different Atos boxes connected.
        .NOTES
            Created: 07/15/2019 by Manuel Martinez, Version 1.0
            Github: https://www.github.com/manuelmartinez-it
            This script was created specifically for PowerShell Core running on MacOS. In the
            event the script is tried to run on Windows or Linux it will try to run and stop
            returning a error that this will only run on MacOS.
    #>
    [CmdletBinding()]
    param (
        # Password to set on ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxPasswd,

        # Hostname to set on ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxHostname,

        # VLAN ID used for ESXi management
        [Parameter(Mandatory)]
        [string]
        $EsxVlanId,

        # IP Address to assign to ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxIpAddr,

        # Subnet to assign to management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxSubnet,

        # Default gateway for management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxGateway,

        # First DNS address for management IP of ESXi host
        [Parameter(Mandatory)]
        [string]
        $EsxDns1,

        # Second DNS address for management IP of ESXi host
        [Parameter(Mandatory = $false)]
        [string]
        $EsxDns2,

        # First nic to add for management
        [Parameter(Mandatory)]
        [string]
        $EsxFirstNic,

        # Second nic to add for management
        [Parameter(Mandatory = $false)]
        [string]
        $EsxSecondNic,

        # Version of ESXi to use
        [Parameter(Mandatory = $false)]
        [string]
        $EsxBuild
    )

    begin {
        Read-MsOsType
    }

    process {
        # Gets the ESXi ISO version to use
        if ($EsxBuild) {
            $isoFiles = Format-EsxUsb -EsxVersion $EsxBuild
            # $isoFiles = Get-EsxIsoVersion -EsxIsoVer $EsxBuild
        } else {
            $isoFiles = Format-EsxUsb
            # $isoFiles = Get-EsxIsoVersion
        }

        if (!$isoFiles) {
            break
        }

        $volumeEsxIso = $isoFiles[0]
        $newUsbName = $isoFiles[1]

        # Copies the ESXi files to the USB drive
        Write-Host -Object "Creating the USB drive as a bootable installer with required files" -ForegroundColor Blue
        Copy-Item -Recurse -Path /Volumes/$volumeEsxIso/* -Destination /Volumes/$newUsbName

        # Rename the ISOLINUX.CFG file to SYSLINUX.CFG
        Rename-Item -Path /Volumes/$newUsbName/ISOLINUX.CFG /Volumes/$newUsbName/SYSLINUX.CFG

        # Edits the BOOT.CFG files to point to kickstart script, change timeout, and edit the title
        Set-BootCfg -UsbName $newUsbName

        # Create the ks.cfg file
        if ($EsxSecondNic -and $EsxDns2) {
            $ksConfig = New-KsConfig -passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -dns2 $EsxDns2 -firstNic $EsxFirstNic -secondNic $EsxSecondNic
        }
        elseif ($EsxSecondNic -and !$EsxDns2) {
            $ksConfig = New-KsConfig -passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -firstNic $EsxFirstNic -secondNic $EsxSecondNic
        } 
        elseif (!$EsxSecondNic -and $EsxDns2) {
            $ksConfig = New-KsConfig -passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -dns2 $EsxDns2 -firstNic $EsxFirstNic
        }
        elseif (!$EsxSecondNic -and !$EsxDns2){
            $ksConfig = New-KsConfig -passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -firstNic $EsxFirstNic
        }
                
        New-Item -Path /Volumes/$newUsbName/ks.cfg -Value $ksConfig | Out-Null

        # Unmount the USB ESXi unattended installer
        $newUsb = Get-DiskUtilIdentifier -DiskIdString $newUsbName
        diskutil unmountDisk $newUsb | Out-Null

        Write-Host -Object "The creation of the ESXi $newUsbName USB unattended disk is complete on $newUsb" -ForegroundColor Blue 
        Write-Host -Object "The disk $newUsb has been unmounted and is safe for removal" -ForegroundColor Green
        say "The ESX USB installer has been created successfully"
    }   
}

#########################################################

function New-BulkEsxUsb {
    <#
        .SYNOPSIS
            Creates multiple new ESXi 6.7U2a USB unattended install disks on MacOS.
        .DESCRIPTION
            Using PowerShell Core on MacOS this will create multiple ESXi USB unattended 
            install disks to be used for multiple hosts. This requires the use of a csv file to
            populate the required information for each of the USB drives. The disks can then be 
            used to boot on a system and it will perform an unattended installation of ESXi on 
            the same USB that was created using this command.
        .EXAMPLE
            New-BulkEsxUsb -CsvPath ~/Desktop/EsxInstall/BulkEsx.csv
            This creates multiple ESXi 6.7U2a USB unattended install disks using the information
            provided in the required csv file.
        .NOTES
            Created: 07/18/2019 by Manuel Martinez, Version 1.0
            Github: https://www.github.com/manuelmartinez-it
            This script was created specifically for PowerShell Core running on MacOS. In the
            event the script is tried to run on Windows or Linux it will try to run and stop
            returning a error that this will only run on MacOS.
    #>
    [CmdletBinding()]
    param (
        # Path to CSV file
        [Parameter(Mandatory)]
        [string]
        $CsvPath
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        # Checks the formatting of the CSV to determine the proper command structure
        # Write-Host -Object "Enter the path to the CSV to build the ESXi USBs: " -NoNewline -ForegroundColor Green
        # $csvPath = Read-Host
        $csvHosts = Find-EsxCsv -FilePath $csvPath

        # Passes the CSV import into an array object list
        $esxHosts = New-Object System.Collections.ArrayList
        foreach ($csvHost in $csvHosts) {
            $esxHosts.Add($csvHost) | Out-Null
        }

        # Gets the ESXi ISO version to use
        if ($EsxBuildVer) {
            $isoInfo = Get-EsxIsoVersion -EsxIsoVer $EsxBuildVer
        }
        else {
            $isoInfo = Get-EsxIsoVersion
        }

        if (!$isoInfo) {
            break
        }
        $newUsbName = $isoInfo[1]
        $isoName = $isoInfo[0]

        

    }

}

#########################################################

function Find-EsxCsv {
    <#
        .SYNOPSIS
            Checks the path given for the CSV location to make sure it's a 
            valid path and imports the headers
    #>
    [CmdletBinding()]
    param (
        # File path the the csv
        [Parameter(Mandatory)]
        [string]
        $FilePath
    )
    
    begin {
        Read-MsOsType
    }
    
    process {
        # Checks to make sure that the file path given has a CSV file
        $findCsv = Test-Path -Path $FilePath -Include "*.csv"
        if ($findCsv -eq $false) {
            Write-Error -Message "The specified path to csv is incorrect, please verify path of csv and try again"
            break
        } else {
            # $esxHosts = Import-Csv -Path $FilePath
            $csvImportHosts = Import-Csv -Path $FilePath
        }
<#
        # Gets the imported csv headers
        $csvHeaders = $esxHosts[0].psobject.properties.name

        # Headers to match against CSV for command to use
        $set1 = @('Passwd','Hostname','VlanId','IpAddr','Subnet','Gateway','Dns1','Nic1')
        [string]$set1String = $null
        $set1String = $set1 -join ","
        $set2 = @('Passwd','Hostname','VlanId','IpAddr','Subnet','Gateway','Dns1','Dns2','Nic1')
        [string]$set2String = $null
        $set2String = $set2 -join ","
        $set3 = @('Passwd','Hostname','VlanId','IpAddr','Subnet','Gateway','Dns1','Dns2','Nic1','Nic2')
        [string]$set3String = $null
        $set3String = $set3 -join ","
        $set4 = @('Passwd','Hostname','VlanId','IpAddr','Subnet','Gateway','Dns1','Nic1','Nic2')
        [string]$set4String = $null
        $set4String = $set4 -join ","

        # Places all the proper header columns into an array and compares against imported CSV
        $sets = @($set1,$set2,$set3,$set4)

        foreach ($set in $sets) {
            $result = Compare-Object -ReferenceObject $csvHeaders -DifferenceObject $set
            if ($null -eq $result) {
                $commandSet = $set
            }
        }

        # Takes matching header array and determines witch KsConfig command to use
        [string]$commands = $null
        $commands = $commandSet -join ","

        switch ($commands) {
            $set1String { $ksCommand = "-passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -firstNic $EsxFirstNic" }
            $set2String { $ksCommand = "-passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -dns2 $EsxDns2 -firstNic $EsxFirstNic" }
            $set3String { $ksCommand = "-passwd -hostname -vlanId -ipAddr -subnet -gateway -dns1 -dns2 -firstNic -secondNic" }
            $set4String { $ksCommand = "-passwd $EsxPasswd -hostname $EsxHostname -vlanId $EsxVlanId -ipAddr $EsxIpAddr -subnet $EsxSubnet -gateway $EsxGateway -dns1 $EsxDns1 -firstNic $EsxFirstNic -secondNic $EsxSecondNic" }
            Default { Write-Error -Message "The CSV isn't formated correctly with the proper columns/headers"}
        }
#>
        # return $ksCommand
        return $csvImportHosts
    }

}

#########################################################