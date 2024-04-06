## This tool will change domain, enforces MFA, and add available license to tenant.
## Designed by Andy Pham

# Function to install and import a PowerShell module
function Ensure-Module {
    param (
        [string]$ModuleName,
        [string]$Scope = "CurrentUser"
    )
    if (-not (Get-Module -ListAvailable -Name $ModuleName)) {
        try {
            Install-Module -Name $ModuleName -Scope $Scope -ErrorAction Stop
        } catch {
            Write-Host "Error installing module $ModuleName: $_"
            return $false
        }
    }
    Import-Module $ModuleName -ErrorAction SilentlyContinue
    return $true
}

# Install and import required modules
$requiredModules = @("MSOnline", "AzureAD", "Microsoft.Graph")
foreach ($module in $requiredModules) {
    if (-not (Ensure-Module -ModuleName $module)) {
        Write-Host "Cannot proceed without required modules."
        return
    }
}

## Start Microsoft Online Login Session
Write-Host "Connecting to Office 365..."
try {
    Connect-MsolService -ErrorAction Stop
    Write-Host "Login Successful"
} catch {
    Write-Host "Failed to connect to Microsoft Online: $_"
    return
}

## Changing Domain
Write-Host "Changing Email Domains"; Start-Sleep -Seconds 3
$newEmail = Read-Host -Prompt "Please enter new email"
$oldEmail = Read-Host -Prompt "Please enter old email"

# Email format validation (basic example)
if ($newEmail -notmatch "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$") {
    Write-Host "Invalid email format."
    return
}

try {
    Set-MsolUserPrincipalName -NewUserPrincipalName $newEmail -UserPrincipalName $oldEmail -ErrorAction Stop
    Write-Host "Tenant's email has changed from $oldEmail to $newEmail"
} catch {
    Write-Host "Failed to change email domain: $_"
    return
}

## Enable MFA
Write-Host "Enable Enforcing Mult-Factor Authentication"; Start-Sleep -Seconds 3
$mf = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$mf.RelyingParty = "*"
$mfa = @($mf)

try {
    Set-MsolUser -UserPrincipalName $newEmail -StrongAuthenticationRequirements $mfa -ErrorAction Stop
    Write-Host "Enabling MFA Complete"
} catch {
    Write-Host "Failed to enable MFA: $_"
    return
}

## Applying License to Tenant
Write-Host "Adding Microsoft 365 Business License to Tenant"
Connect-Graph -Scopes User.ReadWrite.All, Organization.Read.All

$PremiumSku = Get-MgSubscribedSku -All | Where-Object SkuPartNumber -eq 'O365_BUSINESS_PREMIUM'
if ($null -eq $PremiumSku) {
    Write-Host "No suitable license found."
    return
}

try {
    Set-MgUserLicense -UserId "$newEmail" -AddLicenses @{SkuId = $PremiumSku.SkuId} -RemoveLicenses @() -ErrorAction Stop
    Write-Host "Successfully Added License"
} catch {
    Write-Host "Failed to add license: $_"
    return
}
