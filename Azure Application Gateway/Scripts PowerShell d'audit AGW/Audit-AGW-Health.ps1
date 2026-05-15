<#
.SYNOPSIS
    Bilan de santé en 12 points d'une Application Gateway V2.

.DESCRIPTION
    Exécute les 12 vérifications du Chapitre 19 et retourne un objet
    PowerShell avec Pass/Fail par point, un score global, et une
    recommandation contextuelle. Refuse les régions hors France Central /
    West Europe / North Europe.

.PARAMETER ResourceGroupName
    Nom du Resource Group contenant l'AGW.

.PARAMETER AppGatewayName
    Nom de l'Application Gateway à auditer.

.PARAMETER OutputFormat
    Format de sortie : Console (défaut), Json, ou Markdown.

.EXAMPLE
    .\Audit-AGW-Health.ps1 -ResourceGroupName "rg-client-prod-westeu" `
                           -AppGatewayName "agw-client-prod-westeu"

.EXAMPLE
    .\Audit-AGW-Health.ps1 -ResourceGroupName "rg-client-prod-westeu" `
                           -AppGatewayName "agw-client-prod-westeu" `
                           -OutputFormat Json | Out-File audit.json

.NOTES
    Auteur       : Doctor Kloud
    Version      : 1.0.0
    Dernière revue : 2026-05
    Compatibilité : PowerShell 7.2+, Az.Network 7.5+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ResourceGroupName,

    [Parameter(Mandatory)]
    [string]$AppGatewayName,

    [ValidateSet('Console', 'Json', 'Markdown')]
    [string]$OutputFormat = 'Console'
)

# ─────────────────────────────────────────────────────────────────
# Pattern v3.1 #12 — Cristallisation des règles dans le code
# Régions Doctor Kloud autorisées (zone francophone uniquement)
# ─────────────────────────────────────────────────────────────────
$AllowedRegions = @('francecentral', 'westeurope', 'northeurope')

# ─────────────────────────────────────────────────────────────────
# Récupération de l'AGW + validation région
# ─────────────────────────────────────────────────────────────────
try {
    $agw = Get-AzApplicationGateway -ResourceGroupName $ResourceGroupName `
                                    -Name $AppGatewayName -ErrorAction Stop
}
catch {
    Write-Host "[FAIL] AGW '$AppGatewayName' introuvable dans '$ResourceGroupName'." -ForegroundColor Red
    Write-Host "       Erreur : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

$region = $agw.Location.ToLower()
if ($region -notin $AllowedRegions) {
    Write-Host "[FAIL] Région '$region' non autorisée par la gouvernance." -ForegroundColor Red
    Write-Host "       Régions autorisées : $($AllowedRegions -join ', ')" -ForegroundColor Yellow
    Write-Host "       Si ta mission justifie une exception, adapte la liste blanche en haut du script." -ForegroundColor Yellow
    exit 2
}

Write-Host "`n=== Bilan de santé AGW : $AppGatewayName (région : $region) ===" -ForegroundColor Cyan

$results = [ordered]@{}

# ─────────────────────────────────────────────────────────────────
# Point 1 — SKU V2 (Standard_V2 ou WAF_V2)
# ─────────────────────────────────────────────────────────────────
$skuName = $agw.Sku.Name
$results['1_SKU_V2'] = if ($skuName -match 'V2$') {
    @{ Status = 'Pass'; Detail = "SKU = $skuName" }
} else {
    @{ Status = 'Fail'; Detail = "SKU = $skuName (V1 obsolète, migrer vers V2)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 2 — Zones [1, 2, 3] activées
# ─────────────────────────────────────────────────────────────────
$zones = $agw.Zones
$results['2_ZoneRedundant'] = if ($zones -and $zones.Count -ge 3) {
    @{ Status = 'Pass'; Detail = "Zones : $($zones -join ', ')" }
} else {
    @{ Status = 'Fail'; Detail = "Zones configurées : $($zones -join ', ' | Out-String) — 3 zones recommandées" }
}

# ─────────────────────────────────────────────────────────────────
# Point 3 — Autoscale activé avec min ≥ 2
# ─────────────────────────────────────────────────────────────────
$autoscale = $agw.AutoscaleConfiguration
$results['3_Autoscale'] = if ($autoscale -and $autoscale.MinCapacity -ge 2) {
    @{ Status = 'Pass'; Detail = "Autoscale min=$($autoscale.MinCapacity), max=$($autoscale.MaxCapacity)" }
} else {
    @{ Status = 'Fail'; Detail = "Autoscale absent ou min < 2 (jamais min=0)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 4 — WAF Policy attachée et en mode Prevention
# ─────────────────────────────────────────────────────────────────
if ($agw.FirewallPolicy -and $agw.FirewallPolicy.Id) {
    try {
        $wafPolicyId = $agw.FirewallPolicy.Id
        $wafPolicy = Get-AzResource -ResourceId $wafPolicyId -ExpandProperties -ErrorAction Stop
        $wafMode = $wafPolicy.Properties.PolicySettings.mode
        $results['4_WAF_Prevention'] = if ($wafMode -eq 'Prevention') {
            @{ Status = 'Pass'; Detail = "WAF en mode Prevention" }
        } else {
            @{ Status = 'Fail'; Detail = "WAF en mode '$wafMode' (Detection prolongé = Pathologie P9)" }
        }
    }
    catch {
        $results['4_WAF_Prevention'] = @{ Status = 'Fail'; Detail = "Erreur lecture WAF Policy : $($_.Exception.Message)" }
    }
} else {
    $results['4_WAF_Prevention'] = @{ Status = 'Fail'; Detail = "Aucune WAF Policy attachée" }
}

# ─────────────────────────────────────────────────────────────────
# Point 5 — HTTPS only (au moins 1 redirect HTTP→HTTPS)
# ─────────────────────────────────────────────────────────────────
$redirectConfigs = $agw.RedirectConfigurations | Where-Object {
    $_.RedirectType -eq 'Permanent' -and $_.TargetListener
}
$results['5_HTTPSOnly'] = if ($redirectConfigs.Count -gt 0) {
    @{ Status = 'Pass'; Detail = "$($redirectConfigs.Count) redirection(s) HTTP→HTTPS configurée(s)" }
} else {
    @{ Status = 'Warning'; Detail = "Aucune redirection HTTP→HTTPS détectée (Pathologie P7)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 6 — Certificats via Key Vault Reference (au moins 1)
# ─────────────────────────────────────────────────────────────────
$kvCerts = $agw.SslCertificates | Where-Object { $_.KeyVaultSecretId }
$results['6_KeyVaultReference'] = if ($kvCerts.Count -gt 0) {
    @{ Status = 'Pass'; Detail = "$($kvCerts.Count) certificat(s) via Key Vault Reference" }
} else {
    @{ Status = 'Fail'; Detail = "Aucun certificat via Key Vault — uploads manuels = dette (Pathologie P13)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 7 — User-Assigned Managed Identity configurée
# ─────────────────────────────────────────────────────────────────
$identityType = $agw.Identity.Type
$results['7_ManagedIdentity'] = if ($identityType -match 'UserAssigned') {
    @{ Status = 'Pass'; Detail = "User-Assigned MI configurée" }
} else {
    @{ Status = 'Fail'; Detail = "Identité = '$identityType' (User-Assigned recommandée)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 8 — Backend pools tous Healthy
# ─────────────────────────────────────────────────────────────────
try {
    $BackendHealth = Get-AzApplicationGatewayBackendHealth `
        -ResourceGroupName $ResourceGroupName `
        -Name $AppGatewayName -ErrorAction Stop

    $unhealthy = $BackendHealth.BackendAddressPools.BackendHttpSettingsCollection.Servers |
                 Where-Object { $_.Health -ne 'Healthy' }

    $results['8_BackendsHealthy'] = if ($unhealthy.Count -eq 0) {
        @{ Status = 'Pass'; Detail = "Tous les Backends Healthy" }
    } else {
        @{ Status = 'Fail'; Detail = "$($unhealthy.Count) Backend(s) Unhealthy" }
    }
}
catch {
    $results['8_BackendsHealthy'] = @{ Status = 'Warning'; Detail = "Impossible d'évaluer : $($_.Exception.Message)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 9 — Custom probes configurées (au moins 1)
# ─────────────────────────────────────────────────────────────────
$customProbes = $agw.Probes | Where-Object { $_.Path -ne '/' }
$results['9_CustomProbes'] = if ($customProbes.Count -gt 0) {
    @{ Status = 'Pass'; Detail = "$($customProbes.Count) custom probe(s) configurée(s)" }
} else {
    @{ Status = 'Fail'; Detail = "Aucune custom probe — default sur '/' = Pathologie P5" }
}

# ─────────────────────────────────────────────────────────────────
# Point 10 — Diagnostic Settings activés
# ─────────────────────────────────────────────────────────────────
try {
    $diagSettings = Get-AzDiagnosticSetting -ResourceId $agw.Id -ErrorAction Stop
    $results['10_DiagnosticSettings'] = if ($diagSettings.Count -gt 0) {
        @{ Status = 'Pass'; Detail = "$($diagSettings.Count) Diagnostic Setting(s) actif(s)" }
    } else {
        @{ Status = 'Fail'; Detail = "Aucun Diagnostic Setting (Pathologie P12)" }
    }
}
catch {
    $results['10_DiagnosticSettings'] = @{ Status = 'Warning'; Detail = "Erreur lecture : $($_.Exception.Message)" }
}

# ─────────────────────────────────────────────────────────────────
# Point 11 — Tags obligatoires (Environment, Owner, CostCenter)
# ─────────────────────────────────────────────────────────────────
$requiredTags = @('Environment', 'Owner', 'CostCenter')
$missingTags = $requiredTags | Where-Object { -not $agw.Tag.ContainsKey($_) }
$results['11_TagsObligatoires'] = if ($missingTags.Count -eq 0) {
    @{ Status = 'Pass'; Detail = "Tous les tags obligatoires présents" }
} else {
    @{ Status = 'Fail'; Detail = "Tags manquants : $($missingTags -join ', ')" }
}

# ─────────────────────────────────────────────────────────────────
# Point 12 — NSG GatewayManager 65200-65535 sur Subnet AGW
# ─────────────────────────────────────────────────────────────────
try {
    $SubnetId = $agw.GatewayIPConfigurations[0].Subnet.Id
    $vnetName = ($SubnetId -split '/')[8]
    $SubnetName = ($SubnetId -split '/')[10]
    $vnetRg = ($SubnetId -split '/')[4]

    $vnet = Get-AzVirtualNetwork -ResourceGroupName $vnetRg -Name $vnetName -ErrorAction Stop
    $Subnet = $vnet.Subnets | Where-Object { $_.Name -eq $SubnetName }

    if ($Subnet.NetworkSecurityGroup) {
        $nsg = Get-AzNetworkSecurityGroup -ResourceId $Subnet.NetworkSecurityGroup.Id
        $hasGwRule = $nsg.SecurityRules | Where-Object {
            $_.SourceAddressPrefix -eq 'GatewayManager' -and
            $_.DestinationPortRange -match '65200-65535'
        }
        $results['12_NSG_GatewayManager'] = if ($hasGwRule) {
            @{ Status = 'Pass'; Detail = "Règle GatewayManager 65200-65535 présente" }
        } else {
            @{ Status = 'Fail'; Detail = "Règle GatewayManager 65200-65535 manquante (trafic Microsoft bloqué)" }
        }
    } else {
        $results['12_NSG_GatewayManager'] = @{ Status = 'Warning'; Detail = "Aucun NSG sur Subnet AGW (acceptable mais à documenter)" }
    }
}
catch {
    $results['12_NSG_GatewayManager'] = @{ Status = 'Warning'; Detail = "Erreur évaluation NSG : $($_.Exception.Message)" }
}

# ─────────────────────────────────────────────────────────────────
# Synthèse et scoring
# ─────────────────────────────────────────────────────────────────
$passCount = ($results.Values | Where-Object { $_.Status -eq 'Pass' }).Count
$score = "$passCount/12"

$recommendation = switch ($passCount) {
    { $_ -ge 11 } { 'Conforme — AGW saine' }
    { $_ -ge 8 }  { 'À remédier — points faibles identifiés' }
    default       { 'Critique — refonte recommandée' }
}

# Sortie selon format demandé
switch ($OutputFormat) {
    'Console' {
        foreach ($key in $results.Keys) {
            $r = $results[$key]
            $color = switch ($r.Status) {
                'Pass'    { 'Green' }
                'Warning' { 'Yellow' }
                'Fail'    { 'Red' }
            }
            Write-Host ("[{0}] {1,-25} {2}" -f $r.Status, $key, $r.Detail) -ForegroundColor $color
        }
        Write-Host "`nScore : $score" -ForegroundColor Cyan
        Write-Host "Recommandation : $recommendation`n" -ForegroundColor Cyan
    }
    'Json' {
        [pscustomobject]@{
            AppGateway     = $AppGatewayName
            Region         = $region
            Score          = $score
            Recommendation = $recommendation
            Results        = $results
            Timestamp      = (Get-Date).ToString('o')
        } | ConvertTo-Json -Depth 5
    }
    'Markdown' {
        "# Audit AGW : $AppGatewayName`n"
        "**Région** : $region  "
        "**Score** : $score  "
        "**Recommandation** : $recommendation`n"
        "| Point | Statut | Détail |"
        "|-------|--------|--------|"
        foreach ($key in $results.Keys) {
            "| $key | $($results[$key].Status) | $($results[$key].Detail) |"
        }
    }
}
