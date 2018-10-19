# KerberosTestPages
Copy aspx files and the web.config to your webserver and follow the check list:

1. **DNS:** Create the A record in the DNS (e.g. mySiteName) 
2. **Load-Balancer:** (Optional) Create the WebFarm with the backend pool servers 
3. **Active Directory:** Create a Domain account for the Application Pool's identity (e.g. myDomain\myAppPoolaccount) 
4. **Active Directory:** Configure the SPN (NetBIOS and FQDN) on the Application Pool's identity:
```dos
setspn -a http/mySiteName myDomain\myAppPoolaccount
setspn -a http/mySiteName.myDomain.com myDomain\myAppPoolaccount
```

5. Active Directory: Configure the delegation settings (Constrained or Unconstrained) 
6. **IIS:** Create the new Website and Application Pool 
7. **IIS:** Set the Application Pool's identity 
8. **IIS:** Remove NTLM from the NTAuthenticationProviders:
```dos
appcmd.exe set config -section:system.webServer/security/authentication/windowsAuthentication /-"providers.[value='NTLM']" /commit:apphost
```

9. **IIS:** Turn on server-wide session-based authentication for Kerberos:
```dos
appcmd.exe set config -section:windowsAuthentication /authPersistNonNTLM:"True" /commit:apphost
```

10. **IIS:** Set the useAppPoolCredentials flag:
```dos
appcmd.exe set config -section:system.webServer/security/authentication/windowsAuthentication /useAppPoolCredentials:"True" /commit:apphost
```

11. **IE:** Verify Windows Integrated Authentication is enabled 
12. **IE:** Add the site to the Trusted Sites and set 'Automatic logon with current user name and password' on the zone  
13. **Chrome:** Add the AuthNegotiateDelegateWhitelist policy:
```dos
reg.exe add HKLM\Software\Policies\Google\Chrome /v AuthNegotiateDelegateWhitelist /d "*" /f
```


