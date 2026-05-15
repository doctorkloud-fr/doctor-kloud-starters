<#
.SYNOPSIS
    Diagnostic Backend détaillé d'une Application Gateway.

.DESCRIPTION
    Pour chaque Backend pool, retourne le détail des cibles, leur état
    Healthy/Unhealthy, le code retour de la dernière probe, et le message
    d'erreur éventuel. Export CSV optionnel.

.PARAMETER ResourceGroupName
    Resource Group contenant l'AGW.

.PARAMETER AppGatewayName
    Nom de l'AGW.

.PARAMETER ExportPath
    Chemin d'export CSV (optionnel).

.EXAMPLE
    .\Get-AGW-BackendHealth-Detailed.ps1 -ResourceGroupName "rg-client-prod-westeu" `
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
    [string]$ExportPath
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
try {
    $health = Get-AzApplicationGatewayBackendHealth -ResourceGroupName $ResourceGroupName -Name $AppGatewayName -ErrorAction Stop
} catch {
    Write-Host "[FAIL] Backend health echoue : $($_.Exception.Message)" -ForegroundColor Red; exit 3
}
Write-Host "`n=== Diagnostic Backend : $AppGatewayName ===" -ForegroundColor Cyan
$report = foreach ($pool in $health.BackendAddressPools) {
    foreach ($settings in $pool.BackendHttpSettingsCollection) {
        foreach ($server in $settings.Servers) {
            $color = if ($server.Health -eq "Healthy") { "Green" } else { "Red" }
            $log = if ($server.HealthProbeLog) { $server.HealthProbeLog } else { "OK" }
            Write-Host ("[{0,-9}] Pool={1} | Server={2} | {3}" -f $server.Health, $pool.BackendAddressPool.Id.Split("/")[-1], $server.Address, $log) -ForegroundColor $color
            [pscustomobject]@{
                Pool           = $pool.BackendAddressPool.Id.Split("/")[-1]
                BackendSetting = $settings.BackendHttpSettings.Id.Split("/")[-1]
                Address        = $server.Address
                Health         = $server.Health
                HealthProbeLog = $log
                Timestamp      = (Get-Date).ToString("o")
            }
        }
    }
}
if ($ExportPath) {
    $report | Export-Csv -Path $ExportPath -NoTypeInformation -Encoding UTF8
    Write-Host "`nExport CSV : $ExportPath" -ForegroundColor Cyan
}
return $report
