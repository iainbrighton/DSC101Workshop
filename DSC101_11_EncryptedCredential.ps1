## Genereate a certificate with the Document Encryption ehanced key usage
$certificate = New-SelfSignedCertificate -Type DocumentEncryptionCertLegacyCsp -DnsName 'DscEncryptionCert' -HashAlgorithm SHA256
## Export the public certificate used to encrypt the credential
$certificate | Export-Certificate -FilePath ~\DscPublicKey.cer -Force

#region Configure the LCM to use the private certificate (to decrypt credentials)

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
            CertificateID = $certificate.Thumbprint;
        }
    
    } #end node
} #end configuration

## Compile the v5LCM configuration meta.mof
DSC101v5LCM -OutputPath ~\

## Push the meta.mof LCM confiuration
Set-DscLocalConfigurationManager -Path ~\ -Verbose -Force

#endregion

#region Compile a configuration, using the public certificate to encrypt credentials

$configData = @{
    AllNodes = @(
        @{
            NodeName                    = 'localhost';
            CertificateFile             = "~\DscPublicKey.cer";
            Thumbprint                  = $certificate.Thumbprint;
        }
    )
}

Configuration DSC101EncryptedCredential {
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

DSC101EncryptedCredential -OutputPath ~\ -ConfigurationData $configData -Credential (Get-Credential $env:USERNAME)

#endregion

## View the mof document
PSEdit ~\localhost.mof
