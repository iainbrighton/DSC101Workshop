#region Reset LCM (to remove any partial configurations)

[DSCLocalConfigurationManager()]
configuration DSC101v5LCM {
    param (
        [System.String[]] $ComputerName = 'localhost'
    )

    node $ComputerName {

        Settings {
            RebootNodeIfNeeded = $true;
            DebugMode = 'ForceModuleImport';
            AllowModuleOverwrite = $true;
        }
    
    } #end node
} #end configuration

DSC101v5LCM -OutputPath ~\
Set-DscLocalConfigurationManager -Path ~\ -Verbose

#endregion

$rootPath = 'C:\DscSmbShare';
$configurationId = '16db7357-9083-4806-a80c-ebbaf4acd6c1';

configuration DSC101SmbPullServer {
    param (
        [System.String[]] $ComputerName = 'localhost',
        [System.String] $RootPath = 'C:\DscSmbShare'
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xSmbShare;
    Import-DscResource -ModuleName cNtfsAccessControl;

    node $ComputerName {

        File 'ShareRoot' {
            DestinationPath = $rootPath;
            Type            = 'Directory';
            Ensure          = 'Present';
        }

        ## Computer accounts require read access to be able to pull configurations. This demo
        ## only works as the local computer has access via the 'Authenticated Users' group!
        xSMBShare 'DscShare' {
            Name                  = 'DscSmbShare';
            Path                  = $rootPath;
            FullAccess            = 'BUILTIN\Administrators';
            ReadAccess            = 'NT AUTHORITY\Authenticated Users';
            FolderEnumerationMode = 'AccessBased';
            Ensure                = 'Present';
            DependsOn             = '[File]ShareRoot';
        }

        cNtfsPermissionEntry 'NtfsReadExecute' {
            Path = $rootPath;
            Principal = 'NT AUTHORITY\Authenticated Users';
            AccessControlInformation = @(
                cNtfsAccessControlInformation {
                    AccessControlType  = 'Allow';
                    FileSystemRights   = 'ReadAndExecute';
                    Inheritance        = 'ThisFolderSubfoldersAndFiles';
                    NoPropagateInherit = $false;
                }
            )
            Ensure    = 'Present';
            DependsOn = '[File]ShareRoot';
        }
    } #end node
} #end configuration

DSC101SmbPullServer -OutputPath ~\
Start-DscConfiguration -Path ~\ -Wait -Force -Verbose

#region LCM Pull Client configuration

[DSCLocalConfigurationManager()]
configuration DSC101v5LCMSmbPullClient {
    param (
        [Parameter(Mandatory)] [System.String] $ConfigurationId,
        [System.String[]] $ComputerName = 'localhost',
        [System.String] $RootPath = 'C:\DscSmbShare'
    )

    node $ComputerName {

        Settings {
            RefreshMode          = 'Pull';
            RefreshFrequencyMins = 30;
            RebootNodeIfNeeded   = $true;
            ConfigurationID      = $configurationId;
        }

        ConfigurationRepositoryShare SmbConfigShare {
            SourcePath = "\\$env:COMPUTERNAME\DscSmbShare";
        }

        <# ResourceRepositoryShare SmbResourceShare {
            SourcePath = "\\$env:COMPUTERNAME\DscSmbShare";
            Credential = $mycreds
        } #>

    } #end node
} #end configuration

DSC101v5LCMSmbPullClient -OutputPath ~\ -ConfigurationId $configurationId
Set-DscLocalConfigurationManager -Path ~\ -Verbose

#endregion

configuration DSC101SmbPullConfig {
    param (
        [Parameter(Mandatory)] [System.String] $ConfigurationId
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;

    node $ConfigurationId {

        File 'SmbPullExample' {
            DestinationPath = 'C:\SmbPullExample.txt';
            Type            = 'File';
            Contents        = 'Example Pull Server configuration';
            Ensure          = 'Present';
        }
    } #end node
} #end configuration

## Compile the configuration using a confiugration ID for a name
DSC101SmbPullConfig -OutputPath ~\ -ConfigurationId $configurationId

## Copy the configuration to the DSC root folder and create a checksum
Copy-Item -Path ".\$configurationId.mof" -Destination $rootPath -Verbose -Force
New-DscChecksum -Path "$rootPath\$configurationId.mof" -Force -Verbose

## Pull and apply the latest configuration from the pull server
Update-DscConfiguration -Wait -Verbose

## Review the configuration (and confirm it's configured to pull)
Get-DscConfigurationStatus
