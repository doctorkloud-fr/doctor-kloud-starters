# Scripts PowerShell — Audit AGW A2i

> 5 scripts de diagnostic et audit pour Application Gateway V2.
> Compatibles PowerShell 7.2+ et Az.Network 7.5+.
> Régions autorisées : francecentral, westeurope, northeurope.

---

## Scripts disponibles

| Script | Description | Usage |
|--------|-------------|-------|
| `Audit-AGW-Health.ps1` | Bilan santé 12 points | Post-déploiement |
| `Get-AGW-BackendHealth-Detailed.ps1` | Diagnostic backend détaillé + export CSV | Incident |
| `Test-AGW-CertificateExpiry.ps1` | Audit expiration certificats KV | Mensuel |
| `Get-AGW-DiagnosticSettings.ps1` | Vérification Diagnostic Settings | Audit |
| `Export-AGW-AuditReport.ps1` | Orchestrateur rapport Markdown complet | Hebdomadaire |

---

## Utilisation rapide

```powershell
