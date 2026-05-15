# Module Bicep AGW V2 — A2i Technologies

> Module production-ready issu de l'Annexe A du guide Doctor Kloud.
> Déploie une AGW V2 complète en moins d'une heure sur un environnement vierge.

---

## Structure
├── main.bicep                        ← Orchestrateur 4 sous-modules
├── environments/
│   ├── dev/lab.bicepparam            ← Paramètres lab A2i
│   ├── staging/staging.bicepparam    ← Paramètres staging
│   └── prod/prod.bicepparam         ← Paramètres production
└── modules/
├── networking/main.bicep        ← VNet + Subnet + NSG + PIP
├── identity/main.bicep          ← User-Assigned MI + RBAC KV
├── appGateway/main.bicep        ← AGW V2 + Listeners + Rules
└── monitoring/main.bicep        ← Diagnostic Settings + Alertes

---

## Prérequis

1. Azure CLI 2.55+ avec Bicep à jour : `az bicep upgrade`
2. Droits Owner sur la souscription cible
3. Key Vault avec certificat Wildcard déjà importé
4. Workspace Log Analytics déjà déployé

---

## Déploiement

```bash
# 1. TOUJOURS lancer what-if avant tout déploiement
az deployment group what-if \
  --resource-group rg-a2i-agw-bicep-westeu \
  --template-file main.bicep \
  --parameters environments/dev/lab.bicepparam

# 2. Déploiement effectif avec confirmation
az deployment group create \
  --resource-group rg-a2i-agw-bicep-westeu \
  --template-file main.bicep \
  --parameters environments/dev/lab.bicepparam \
  --confirm-with-what-if

# 3. Validation post-déploiement
az network application-gateway show-backend-health \
  --name agw-a2i-dev-westeu \
  --resource-group rg-a2i-agw-bicep-westeu \
  -o table
```

---

## Ce que déploie ce module

| Ressource | Nom | Notes |
|-----------|-----|-------|
| VNet | `vnet-{prefix}-network-{env}-{loc}` | CIDR paramétrable |
| Subnet AGW | `snet-agw` | /24 minimum |
| NSG | `nsg-{prefix}-agw-{env}-{loc}` | Règle GatewayManager obligatoire |
| Public IP | `pip-{prefix}-agw-{env}-{loc}` | Standard + zones 1,2,3 |
| Managed Identity | `id-{prefix}-agw-{env}-{loc}` | User-Assigned |
| AGW V2 | `agw-{prefix}-{env}-{loc}` | WAF_V2 + autoscale |
| Diagnostic Settings | `diag-{agwName}` | AccessLog + FirewallLog + AllMetrics |
| Action Groups | P1, P2, P3 | Email CloudOps |
| Alertes | 6 règles | P1×2, P2×2, P3×2 |

---

## Bugs spec corrigés dans ce module

| Bug | Description | Fix appliqué |
|-----|-------------|--------------|
| #27 | Sous-modules BCP091 non rédigés | Tous les sous-modules créés |
| #140 | camelCase dans queries | Nommage cohérent |

---

*Auteur : Doctor Kloud — version 1.0.0 — mai 2026*
