# This tool will change domain from .NET to .COM, enforces MFA, and add available license to tenant. 
# Designed by Andy Pham

#Module Dependency
#MSOnline
#AzureAD
#Microsoft.Graph

"Change arraynetworks.net to arraynetworks.com or zentrysecurity.com"
Start-Sleep -Seconds 3
"Connecting to Office 365..."
if(-not (Get-MsolDomain -ErrorAction SilentlyContinue))
  {
    #Start Microsoft Online Login Session
    "Lauching Microsoft Sign In"
    Import-Module MSOnline
    Connect-MsolService
    "Login Successful"
  }
else {"You have an active Micrsoft Online Session"}
$newEmail = (Read-Host -Prompt "Please enter new email")
$oldEmail = (Read-Host -Prompt "Please enter old email")
set-msoluserprincipalname -newuserprincipalname $newEmail -userprincipalname $oldEmail
"Tenant's email has changed from $oldEmail to $newEmail"

"Enable Enforcing Mult-Factor Authentication"
Start-Sleep -Seconds 3
$mf= New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mf.RelyingParty = "*"
$mfa = @($mf)
Set-MsolUser -UserPrincipalName $newEmail -StrongAuthenticationRequirements $mfa

"Adding Microsoft 365 Business License to Tenant"
Write-Host "Starting Microsoft Graph" ; Start-Sleep -Seconds 3
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All
$e5Sku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'
if(-not (Set-MgUserLicense -UserId "$newEmail" -AddLicenses @{SkuId = $e5Sku.SkuId} -RemoveLicenses @() -ErrorAction SilentlyContinue)) 
  {
    Write-Host "No License Available. Go to Portal."
  }
else {"Successfully Added License"}