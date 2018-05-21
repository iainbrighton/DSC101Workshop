$configData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost';
            PSDscAllowPlainTextPassword = $true;
            #CertificateFile             = "~\DscPublicKey.cer"
            #Thumbprint                  = 'B003ED5F683F4983CA41188F1CC4C30FDDD446FA'
        }
    )
}

Configuration DSC101PlainTextCredential {
    param (
        [Parameter(Mandatory)]
        [System.Management.Automation.PSCredential] $Credential
    )

    Import-DscResource -ModuleName PSDesiredStateConfiguration;

    node $AllNodes.NodeName {

        Registry 'CommandProcessorDefaultColor' {
            Key                  = 'HKEY_CURRENT_USER\SOFTWARE\Microsoft\Command Processor';
            ValueName            = 'DefaultColor';
            ValueData            = '31';
            ValueType            = 'DWORD';
            Ensure               = 'Present';
            Force                = $true;
            PsDscRunAsCredential = $Credential;
        }

    }

}

DSC101PlainTextCredential -OutputPath ~\ -ConfigurationData $configData -Credential (Get-Credential $env:USERNAME)

## View the mof document
PSEdit ~\localhost.mof
