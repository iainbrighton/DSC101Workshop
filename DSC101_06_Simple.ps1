Configuration DSC101Simple {

    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xNetworking;
    Import-DscResource -ModuleName PolicyFileEditor;
    
    xFirewall 'ICMPv4' {
        Name      = 'FPS-ICMP4-ERQ-In';
        Direction = 'Inbound';
        Action    = 'Allow';
        Profile   = 'Any';
        Enabled   = 'True';
    }
    
    xFirewall 'ICMPv6' {
        Name      = 'FPS-ICMP6-ERQ-In';
        Direction = 'Inbound';
        Action    = 'Allow';
        Profile   = 'Any';
        Enabled   = 'True';
    }

    Registry 'DoNotOpenServerManagerAtLogon' {
        Key       = 'HKLM:\Software\Microsoft\ServerManager';
        ValueName = 'DoNotOpenServerManagerAtLogon';
        ValueData = '1';
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

## Compile the configuration to generate the .mof
DSC101Simple -OutputPath ~\
