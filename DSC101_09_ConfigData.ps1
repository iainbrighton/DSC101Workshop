$configData = @{
    AllNodes = @(
        @{
            NodeName             = '*';
            IcmpEnabled          = 'False';
            DisableServerManager = $true;
        }
        @{
            NodeName    = 'localhost';
            IcmpEnabled = 'True';
            IcmpProfile = 'Any';
        }
    )
}

Configuration DSC101ConfigData {
    
    Import-DscResource -ModuleName PSDesiredStateConfiguration;
    Import-DscResource -ModuleName xNetworking;
    Import-DscResource -modulename PolicyFileEditor;

    node $AllNodes.NodeName {

        xFirewall 'ICMPv4' {
            Name      = 'FPS-ICMP4-ERQ-In';
            Direction = 'Inbound';
            Action    = 'Allow';
            Profile   = $node.ICMPProfile;
            Enabled   = $node.ICMPEnabled;
            DependsOn = '[Registry]DoNotOpenServerManagerAtLogon';
        }

        xFirewall 'ICMPv6' {
            Name      = 'FPS-ICMP6-ERQ-In';
            Direction = 'Inbound';
            Action    = 'Allow';
            Profile   = $node.ICMPProfile;
            Enabled   = $node.ICMPEnabled;
            DependsOn = '[Registry]DoNotOpenServerManagerAtLogon';
        }

        Registry 'DoNotOpenServerManagerAtLogon' {
            Key       = 'HKLM:\Software\Microsoft\ServerManager';
            ValueName = 'DoNotOpenServerManagerAtLogon';
            ValueData = $node.DisableServerManager -as [System.Int32];
            ValueType = 'Dword';
        }

        cAdministrativeTemplateSetting 'EnableTranscripting' {
            PolicyType   = 'Machine';
            KeyValueName = 'Software\Policies\Microsoft\Windows\PowerShell\Transcription\EnableTranscripting';
            Type         = 'Dword';
            Data         = '1';
            Ensure       = 'Present';
            DependsOn    = '[xFirewall]ICMPv4','[xFirewall]ICMPv6';
        }

    }

}

DSC101ConfigData -OutputPath ~\ -ConfigurationData $configData
