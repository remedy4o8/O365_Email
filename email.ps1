# This tool will change domain, enforces MFA, and add available license to tenant. 
# Designed by Andy Pham

# Uncomment line 5-11 to install dependency.
# Install-Module MSOnline
# Install-Module AzureAD
# Install-Module Microsoft.Graph -Scope CurrentUser

# Import-Module MSOnline
# Import-Module AzureAD
# Import-Module Microsoft.Graph

Write-Host "Change Email Domains" ; Start-Sleep -Seconds 3
Write-Host "Connecting to Office 365..."
if(-not (Get-MsolDomain -ErrorAction SilentlyContinue))
  {
    #Start Microsoft Online Login Session
    Write-Host "Lauching Microsoft Sign In"
    #Import-Module MSOnline
    Connect-MsolService
    Write-Host "Login Successful"
  }
else {"You have an active Micrsoft Online Session"}
$newEmail = (Read-Host -Prompt "Please enter new email")
$oldEmail = (Read-Host -Prompt "Please enter old email")
set-msoluserprincipalname -newuserprincipalname $newEmail -userprincipalname $oldEmail
Write-Host "Tenant's email has changed from $oldEmail to $newEmail"

Write-Host "Enable Enforcing Mult-Factor Authentication" ; Start-Sleep -Seconds 3
$mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mf.RelyingParty = "*"
$mfa = @($mf)
Set-MsolUser -UserPrincipalName $newEmail -StrongAuthenticationRequirements $mfa
Write-Host "Enabling MFA Complete"

Write-Host "Adding Microsoft 365 Business License to Tenant"
Write-Host "Starting Microsoft Graph" ; Start-Sleep -Seconds 3
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All
$PremiumSku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'
if(-not (Set-MgUserLicense -UserId "$newEmail" -AddLicenses @{SkuId = $PremiumSku.SkuId} -RemoveLicenses @() -ErrorAction SilentlyContinue)) 
  {
    Write-Host "No License Available. Go to Portal."
  }
else {"Successfully Added License"}
