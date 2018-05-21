Configuration DSC101Simple {

    Import-DscResource -ModuleName
    Import-DscResource -ModuleName
    Import-DscResource -ModuleName

    xFirewall a {
        Name = ""     
        Direction
        Action
        Profile
        Enabled
    }
    
    xFirewall b {
        Name      
        Direction
        Action
        Profile
        Enabled
    }
    
    Registry c {
        Key
        ValueName
        ValueData
        ValueType
    }

    cAdministrativeTemplateSetting d {
        PolicyType
        KeyValueName
        Type
        Data
        Ensure
    }

}

## Compile the configuration to generate the .mof
DSC101Simple -OutputPath ~\
