#region Configure the LCM to use two partial configurations

[DSCLocalConfigurationManager()]
configuration DSC101v5LCM {
    param (
        [System.String[]] $ComputerName = 'localhost'
    )

    node $ComputerName {

        PartialConfiguration DSC101FirewallConfig {
            Description = 'Configuration to configure the local firewall.';
            RefreshMode = 'Push';
        }
        
        PartialConfiguration DSC101SecurityConfig {
            Description = 'Configuration to apply standrd security policy.';
            RefreshMode = 'Push';
            DependsOn   = '[PartialConfiguration]DSC101FirewallConfig';
        }
    
    } #end node
} #end configuration

## Compile the v5LCM configuration meta.mof
DSC101v5LCM -OutputPath ~\

## Push the meta.mof LCM confiuration
Set-DscLocalConfigurationManager -Path ~\ -Verbose -Force

#endregion

#region Partial configurations

Configuration DSC101FirewallConfig {
    param (
        ## Enable IP v4 and v6 ping requests through firewall.
        [Parameter()]
        [Boolean] $ICMP
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xNetworking;

    xFirewall 'ICMPv4' {
        Name      = 'FPS-ICMP4-ERQ-In';
        Direction = 'Inbound';
        Action    = 'Allow';
        Profile   = 'Any';
        Enabled   = $ICMP.ToString();
    }
    
    xFirewall 'ICMPv6' {
        Name      = 'FPS-ICMP6-ERQ-In';
        Direction = 'Inbound';
        Action    = 'Allow';
        Profile   = 'Any';
        Enabled   = $ICMP.ToString();
    }

} #end configuration DSC101FirewallConfig

Configuration DSC101SecurityConfig {
    param (
        ## Disable Server Manager start at logon.
        [Parameter(Mandatory)]
        [Switch] $DisableServerManager
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName PolicyFileEditor;

    Registry 'DoNotOpenServerManagerAtLogon' {
        Key       = 'HKLM:\Software\Microsoft\ServerManager';
        ValueName = 'DoNotOpenServerManagerAtLogon';
        ValueData = $DisableServerManager.ToBool() -as [System.Int32];
        ValueType = 'Dword';
    }

    cAdministrativeTemplateSetting 'EnableTranscripting' {
        PolicyType   = 'Machine';
        KeyValueName = 'Software\Policies\Microsoft\Windows\PowerShell\Transcription\EnableTranscripting';
        Type         = 'Dword';
        Data         = '1';
        Ensure       = 'Present';
    }

} #end configuration DSC101SecurityConfig

#endregion

## Published partial configurations must reside in their own directories
Set-Location -Path ~\
## NOTE: No -OutputPath :)
DSC101FirewallConfig -ICMP $true
DSC101SecurityConfig -DisableServerManager

## Publish (push) the configurations
Publish-DscConfiguration ~\DSC101FirewallConfig -Verbose
Publish-DscConfiguration ~\DSC101SecurityConfig -Verbose

## Manually apply the configuration
Start-DscConfiguration -UseExisting -Wait -Force -Verbose
