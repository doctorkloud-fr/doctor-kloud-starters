<#
.SYNOPSIS
    Audit des dates d'expiration des certificats AGW.

.DESCRIPTION
    Liste les Listeners HTTPS, et pour chaque certificat (Key Vault Reference),
    retourne nom, date d'expiration, jours restants, et statut
    (OK > 60j, ALERT 30-60j, CRITICAL < 30j, EXPIRED).

.PARAMETER AlertThresholdDays
    Seuil d'alerte en jours (défaut 60).

.EXAMPLE
    .\Test-AGW-CertificateExpiry.ps1 -ResourceGroupName "rg-client-prod-westeu" `
                                     -AppGatewayName "agw-client-prod-westeu" `
                                     -AlertThresholdDays 45

.NOTES
    Auteur       : Doctor Kloud
    Version      : 1.0.0
    Dernière revue : 2026-05
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AppGatewayName,
    [int]$AlertThresholdDays = 60
)
$AllowedRegions = @("francecentral", "westeurope", "northeurope")
try {
    $agw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName -Name $AppGatewayName -ErrorAction Stop
} catch {
    Write-Host "[FAIL] AGW introuvable : $($_.Exception.Message)" -ForegroundColor Red; exit 1
}
if ($agw.Location.ToLower() -notin $AllowedRegions) {
    Write-Host "[FAIL] Region non autorisee." -ForegroundColor Red; exit 2
}
$now = Get-Date
Write-Host "`n=== Audit certificats : $AppGatewayName ===" -ForegroundColor Cyan
Write-Host "Seuil alerte : $AlertThresholdDays jours`n" -ForegroundColor Cyan

$report = foreach ($cert in $agw.SslCertificates) {
    if (-not $cert.KeyVaultSecretId) {
        Write-Host "[WARN] '$($cert.Name)' uploade manuellement (pas de KV Reference)" -ForegroundColor Yellow
        continue
    }
    $kvUri = [uri]$cert.KeyVaultSecretId
    $kvName = $kvUri.Host.Split(".")[0]
    $secretName = $kvUri.Segments[2].TrimEnd("/")
    try {
        $kvCert = Get-AzKeyVaultCertificate -VaultName $kvName -Name $secretName -ErrorAction Stop
        $expiry = $kvCert.Expires
        $daysRemaining = ($expiry - $now).Days
        $status = if ($daysRemaining -lt 0) { "EXPIRED" } elseif ($daysRemaining -lt 30) { "CRITICAL" } elseif ($daysRemaining -lt $AlertThresholdDays) { "ALERT" } else { "OK" }
        $color = switch ($status) { "OK" { "Green" } "ALERT" { "Yellow" } default { "Red" } }
        Write-Host ("[{0,-8}] {1} | KV={2} | Expire={3:yyyy-MM-dd} | {4}j restants" -f $status, $cert.Name, $kvName, $expiry, $daysRemaining) -ForegroundColor $color
        [pscustomobject]@{
            CertificateName = $cert.Name
            KeyVault        = $kvName
            ExpiryDate      = $expiry
            DaysRemaining   = $daysRemaining
            Status          = $status
        }
    } catch {
        Write-Host "[FAIL] Lecture KV '$kvName/$secretName' : $($_.Exception.Message)" -ForegroundColor Red
    }
}
return $report
