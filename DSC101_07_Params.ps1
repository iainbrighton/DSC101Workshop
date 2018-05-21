Configuration DSC101Params {
    param (
        ## Disable Server Manager start at logon.
        [Parameter(Mandatory)]
        [Switch] $DisableServerManager,

        ## Enable IP v4 and v6 ping requests through firewall.
        [Parameter()]
        [Boolean] $ICMP
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xNetworking;
    Import-DscResource -ModuleName PolicyFileEditor;

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

}

DSC101Params -OutputPath ~\ -DisableServerManager -ICMP $true
