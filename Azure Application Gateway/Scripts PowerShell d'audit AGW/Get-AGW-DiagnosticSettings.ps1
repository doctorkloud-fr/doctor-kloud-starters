<#
.SYNOPSIS
    Vérification de la configuration des Diagnostic Settings AGW.

.DESCRIPTION
    Contrôle l'activation d'AccessLog, FirewallLog (si WAF), AllMetrics,
    la validité du workspace Log Analytics destination, et la rétention.

.EXAMPLE
    .\Get-AGW-DiagnosticSettings.ps1 -ResourceGroupName "rg-client-prod-westeu" `
                                     -AppGatewayName "agw-client-prod-westeu"

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
PS /home/imane/scripts> cat Get-AGW-DiagnosticSettings.ps1           
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AppGatewayName
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
$isWaf = $agw.Sku.Name -match "WAF"
try {
    $diagSettings = Get-AzDiagnosticSetting -ResourceId $agw.Id -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Lecture Diagnostic Settings : $($_.Exception.Message)" -ForegroundColor Red; exit 3
}
if (-not $diagSettings) {
    Write-Host "[FAIL] Aucun Diagnostic Setting configure (Pathologie P12)" -ForegroundColor Red
    return
}
Write-Host "`n=== Diagnostic Settings : $AppGatewayName ===" -ForegroundColor Cyan
Write-Host "SKU WAF : $isWaf | $($diagSettings.Count) setting(s) trouve(s)`n" -ForegroundColor Cyan

foreach ($ds in $diagSettings) {
    Write-Host "--- Setting : $($ds.Name) ---" -ForegroundColor Cyan
    if ($ds.WorkspaceId) {
        try {
            $ws = Get-AzResource -ResourceId $ds.WorkspaceId -ErrorAction Stop
            Write-Host "[Pass] Workspace : $($ws.Name)" -ForegroundColor Green
        } catch {
            Write-Host "[FAIL] Workspace invalide : $($ds.WorkspaceId)" -ForegroundColor Red
        }
    } else {
        Write-Host "[WARN] Pas de Log Analytics workspace" -ForegroundColor Yellow
    }
    $expectedLogs = @("ApplicationGatewayAccessLog", "ApplicationGatewayPerformanceLog")
    if ($isWaf) { $expectedLogs += "ApplicationGatewayFirewallLog" }
    foreach ($logCat in $expectedLogs) {
        $log = $ds.Log | Where-Object { $_.Category -eq $logCat }
        if ($log -and $log.Enabled) {
            Write-Host "[Pass] Log $logCat active" -ForegroundColor Green
        } else {
            Write-Host "[FAIL] Log $logCat desactive ou absent" -ForegroundColor Red
        }
    }
    $allMetrics = $ds.Metric | Where-Object { $_.Category -eq "AllMetrics" -and $_.Enabled }
    if ($allMetrics) {
        Write-Host "[Pass] AllMetrics activees" -ForegroundColor Green
    } else {
        Write-Host "[WARN] AllMetrics non activees" -ForegroundColor Yellow
    }
}
