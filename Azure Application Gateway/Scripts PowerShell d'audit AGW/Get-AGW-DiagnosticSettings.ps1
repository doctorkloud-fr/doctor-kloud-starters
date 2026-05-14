
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
