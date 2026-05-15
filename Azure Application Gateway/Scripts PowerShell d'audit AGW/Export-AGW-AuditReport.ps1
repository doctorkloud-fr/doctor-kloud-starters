<#
.SYNOPSIS
    Génère un rapport d'audit AGW complet en Markdown.
.DESCRIPTION
    Orchestrateur qui exécute les 4 scripts d'audit et compile
    les résultats dans audit-report-YYYYMMDD-HHmm.md
.PARAMETER ResourceGroupName
    Resource Group contenant l'AGW.
.PARAMETER AppGatewayName
    Nom de l'AGW.
.PARAMETER OutputFolder
    Dossier de sortie du rapport (défaut : répertoire courant).
.EXAMPLE
    .\Export-AGW-AuditReport.ps1 -ResourceGroupName "rg-a2i-agw-bicep-westeu" `
                                  -AppGatewayName "agw-a2i-web-dev-westeu"
.NOTES
    Auteur       : Doctor Kloud
    Version      : 1.0.0
    Derniere revue : 2026-05
    Pre-requis   : les 4 autres scripts dans le meme dossier.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ResourceGroupName,
    [Parameter(Mandatory)][string]$AppGatewayName,
    [string]$OutputFolder = "."
)

$AllowedRegions = @("francecentral", "westeurope", "northeurope")

try {
    $agw = Get-AzApplicationGateway `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppGatewayName `
        -ErrorAction Stop
} catch {
    Write-Host "[FAIL] AGW introuvable : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

if ($agw.Location.ToLower() -notin $AllowedRegions) {
    Write-Host "[FAIL] Region non autorisee." -ForegroundColor Red
    exit 2
}

# Fix Bug #132 : PSScriptRoot vide en Cloud Shell
$scriptDir = if ($PSScriptRoot) {
    $PSScriptRoot
} else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

if (-not $scriptDir) {
    $scriptDir = "$HOME/scripts"
}

$timestamp  = Get-Date -Format "yyyyMMdd-HHmm"
$reportPath = Join-Path $OutputFolder "audit-report-$AppGatewayName-$timestamp.md"

Write-Host ""
Write-Host "=== Orchestrateur Audit AGW : $AppGatewayName ===" -ForegroundColor Cyan
Write-Host "Region  : $($agw.Location)"  -ForegroundColor Cyan
Write-Host "Rapport : $reportPath"        -ForegroundColor Cyan
Write-Host "Scripts : $scriptDir"         -ForegroundColor Cyan
Write-Host ""

# Section 1 - Bilan sante
Write-Host "-> Section 1 : Bilan de sante (12 points)..." -ForegroundColor Yellow
$healthMd = & "$scriptDir/Audit-AGW-Health.ps1" `
    -ResourceGroupName $ResourceGroupName `
    -AppGatewayName $AppGatewayName `
    -OutputFormat Markdown 2>&1

# Section 2 - Backend Health
Write-Host "-> Section 2 : Backend Health detaille..." -ForegroundColor Yellow
$backendHealth = & "$scriptDir/Get-AGW-BackendHealth-Detailed.ps1" `
    -ResourceGroupName $ResourceGroupName `
    -AppGatewayName $AppGatewayName 2>&1 | Out-String

# Section 3 - Certificats
Write-Host "-> Section 3 : Audit certificats..." -ForegroundColor Yellow
$certExpiry = & "$scriptDir/Test-AGW-CertificateExpiry.ps1" `
    -ResourceGroupName $ResourceGroupName `
    -AppGatewayName $AppGatewayName 2>&1 | Out-String

# Section 4 - Diagnostic Settings
Write-Host "-> Section 4 : Diagnostic Settings..." -ForegroundColor Yellow
$diagSettings = & "$scriptDir/Get-AGW-DiagnosticSettings.ps1" `
    -ResourceGroupName $ResourceGroupName `
    -AppGatewayName $AppGatewayName 2>&1 | Out-String

Write-Host ""
Write-Host "-> Compilation du rapport Markdown..." -ForegroundColor Yellow

$report = "# Rapport d audit Application Gateway`n`n"
$report += "| Champ | Valeur |`n"
$report += "|-------|--------|`n"
$report += "| AGW | $AppGatewayName |`n"
$report += "| Resource Group | $ResourceGroupName |`n"
$report += "| Region | $($agw.Location) |`n"
$report += "| Date | $(Get-Date -Format 'yyyy-MM-dd HH:mm') |`n"
$report += "| Auditeur | Doctor Kloud Editorial Engine |`n`n"
$report += "---`n`n"
$report += "## Resume executif`n`n"
$report += "Audit automatise execute sur $AppGatewayName selon les 12 points`n"
$report += "du Chapitre 19 et les verifications complementaires.`n`n"
$report += "---`n`n"
$report += "## 1. Bilan de sante (12 points)`n`n"
$report += "$healthMd`n`n"
$report += "---`n`n"
$report += "## 2. Etat detaille des Backends`n`n"
$report += "$backendHealth`n`n"
$report += "---`n`n"
$report += "## 3. Audit des certificats`n`n"
$report += "$certExpiry`n`n"
$report += "---`n`n"
$report += "## 4. Diagnostic Settings`n`n"
$report += "$diagSettings`n`n"
$report += "---`n`n"
$report += "## Recommandations`n`n"
$report += "1. Critique : WAF en mode Detection, Diagnostic Settings absents`n"
$report += "2. Important : Certificats expires ou sans KV Reference`n"
$report += "3. Optimisation : Tags manquants, autoscale min < 2`n`n"
$report += "---`n`n"
$report += "## Bugs connus vs spec`n`n"
$report += "| Bug | Description | Fix |`n"
$report += "|-----|-------------|-----|`n"
$report += "| #67 | BackendResponseTime_d inexistant | WAFEvaluationTime_s |`n"
$report += "| #79 | Champs KQL majuscules | ruleId_s, backendPoolName_s |`n"
$report += "| #111 | test-connectivity incompatible AGW | show-backend-health |`n"
$report += "| #132 | PSScriptRoot vide Cloud Shell | Split-Path MyInvocation |`n`n"
$report += "---`n`n"
$report += "*Rapport genere par Export-AGW-AuditReport.ps1 v1.0.0*`n"

# Creer le dossier si necessaire
if (-not (Test-Path $OutputFolder)) {
    New-Item -ItemType Directory -Force -Path $OutputFolder | Out-Null
}

$report | Out-File -FilePath $reportPath -Encoding UTF8

Write-Host ""
Write-Host "[Pass] Rapport genere avec succes" -ForegroundColor Green
Get-Item $reportPath | Select-Object Name,
    @{N="Taille";E={"{0} KB" -f [math]::Round($_.Length/1KB,1)}},
    LastWriteTime

Write-Host ""
Write-Host "-> Apercu (30 premieres lignes) :" -ForegroundColor Cyan
Get-Content $reportPath | Select-Object -First 30
