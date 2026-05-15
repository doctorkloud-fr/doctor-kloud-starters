# Azure Application Gateway — Starter Kit

> Starter kit issu du guide **"Azure Application Gateway — Le guide du consultant"**
> par Doctor Kloud. Testé sur tenant A2i Technologies — mai 2026.
> **90+ bugs de spec corrigés** et documentés.

---

## 📦 Contenu

| Dossier | Description | Fichiers |
|---------|-------------|---------|
| [`iac-network/`](./iac-network/) | Module Bicep AGW V2 + pipeline CI/CD | 8 fichiers |
| [`Bibliothèque KQL consolidée/`](./Bibliothèque%20KQL%20consolidée%20pour%20AGW%20V2/) | 15 requêtes KQL production-ready | 15 `.kql` |
| [`Plan de tests/`](./Plan%20de%20tests%20AGW%20(T-01%20à%20T-15)/) | Suite de tests T-01 à T-15 | 12 `.sh` |
| [`Scripts PowerShell/`](./Scripts%20PowerShell%20d'audit%20AGW/) | 5 scripts audit et diagnostic | 5 `.ps1` |

---

## 🏗️ Architecture déployée
Internet
↓
Front Door Premium (afd-*-global)
↓
AGW WAF_V2 — zones 1,2,3 — autoscale 2-25 CU
↓ TLS 1.2 min | WAF Prevention | KV Reference
App Services (backend privatisé via PE)
↓
Log Analytics → Workbooks → Alertes P1/P2/P3

---

## ⚡ Démarrage rapide

### Prérequis

- Azure CLI 2.55+ : `az --version`
- Bicep à jour : `az bicep upgrade`
- Droits Owner sur la souscription
- Key Vault + certificat Wildcard existants
- Log Analytics workspace existant

### Déployer en 3 commandes

```bash
cd iac-network

# 1. Adapter les paramètres
cp environments/dev/lab.bicepparam environments/dev/monenv.bicepparam

# 2. What-if obligatoire
az deployment group what-if \
  --resource-group <ton-rg> \
  --template-file modules/agw/main.bicep \
  --parameters environments/dev/monenv.bicepparam

# 3. Déployer
az deployment group create \
  --resource-group <ton-rg> \
  --template-file modules/agw/main.bicep \
  --parameters environments/dev/monenv.bicepparam
```

---

## 🧪 Valider le déploiement

```bash
# Lancer les smoke tests
bash "Plan de tests AGW (T-01 à T-15)/scripts/run-smoke-tests.sh"

# Audit santé 12 points
pwsh "Scripts PowerShell d'audit AGW/Audit-AGW-Health.ps1" \
  -ResourceGroupName <ton-rg> \
  -AppGatewayName <ton-agw>
```

---

## 📊 KQL — Requêtes d'incident

```kql
// Top 502/504 par pool — premier réflexe en incident
AzureDiagnostics
| where Category == "ApplicationGatewayAccessLog"
| where httpStatus_d in (502, 504)
| where TimeGenerated > ago(24h)
| summarize count() by backendPoolName_s
| order by count_ desc
```

→ 15 requêtes dans [`Bibliothèque KQL/`](./Bibliothèque%20KQL%20consolidée%20pour%20AGW%20V2/)

---

## 🐛 Bugs spec corrigés

| # | Description | Impact |
|---|-------------|--------|
| #27 | Sous-modules Bicep non rédigés dans la spec | Critique |
| #67 | `BackendResponseTime_d` inexistant | Toutes requêtes latence |
| #79 | Champs KQL en majuscules (`RuleId_s`, `BackendPoolName_s`) | Toutes requêtes WAF |
| #111 | `test-connectivity` incompatible AGW | Section troubleshooting |
| #139 | DNS fictif non résolvable en lab | Tests T-03, T-05, T-06 |

→ Liste complète dans [`iac-network/BUGS.md`](./iac-network/BUGS.md)

---

## 📖 Guide complet

**[Azure Application Gateway — Le guide du consultant](https://doctorkloud.fr)**
par Hicham KADIRI — Doctor Kloud

---
