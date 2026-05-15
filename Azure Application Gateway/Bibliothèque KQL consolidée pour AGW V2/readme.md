# Bibliothèque KQL — Application Gateway V2 A2i

> 15 requêtes production-ready testées sur `law-a2i-network-prod` — mai 2026.

---

## Index des requêtes

### Catégorie 1 — Performance et latence

| # | Fichier | Usage | Fréquence |
|---|---------|-------|-----------|
| KQL 01 | [kql-01-decomposition-latence-agw-backend.kql](kql-01-decomposition-latence-agw-backend.kql) | Site lent : AGW ou Backend ? | Ad-hoc incident |
| KQL 02 | [kql-02-top20-uri-lentes-p95.kql](kql-02-top20-uri-lentes-p95.kql) | Top 20 URIs les plus lentes | Standup quotidien |
| KQL 03 | [kql-03-latence-hostname-backend-pool.kql](kql-03-latence-hostname-backend-pool.kql) | Latence par Hostname × Backend pool | Investigation |
| KQL 04 | [kql-04-slow-requests-anormales.kql](kql-04-slow-requests-anormales.kql) | Requêtes > 2s — alerte P2 | Règle d'alerte |

### Catégorie 2 — Erreurs et incidents

| # | Fichier | Usage | Fréquence |
|---|---------|-------|-----------|
| KQL 05 | [kql-05-top-5xx-backend-pool.kql](kql-05-top-5xx-backend-pool.kql) | Top 502/504 par Backend pool | Standup quotidien |
| KQL 06 | [kql-06-matrice-erreurs-hostname-code-http.kql](kql-06-matrice-erreurs-hostname-code-http.kql) | Matrice Hostname × code HTTP | Vue d'ensemble |
| KQL 07 | [kql-07-top-client-ips-erreurs.kql](kql-07-top-client-ips-erreurs.kql) | Top IPs en erreurs 4xx/5xx | Détection attaque |
| KQL 08 | [kql-08-detection-502-burst.kql](kql-08-detection-502-burst.kql) | Détection burst 502 | Alerte temps réel |

### Catégorie 3 — WAF et sécurité

| # | Fichier | Usage | Fréquence |
|---|---------|-------|-----------|
| KQL 09 | [kql-09-waf-blocks-par-rule.kql](kql-09-waf-blocks-par-rule.kql) | Top Rules WAF bloquantes | Hebdomadaire |
| KQL 10 | [kql-10-geo-ips-bloquees-waf.kql](kql-10-geo-ips-bloquees-waf.kql) | Géolocalisation IPs bloquées | Investigation |
| KQL 11 | [kql-11-ratio-bloque-rule-hostname.kql](kql-11-ratio-bloque-rule-hostname.kql) | Ratio bloqué > 5% = faux positif | Tuning WAF |
| KQL 12 | [kql-12-top30-rules-blocked-vs-detected.kql](kql-12-top30-rules-blocked-vs-detected.kql) | Blocked vs Detected par Rule | Audit WAF |

### Catégorie 4 — Capacité et tendances

| # | Fichier | Usage | Fréquence |
|---|---------|-------|-----------|
| KQL 13 | [kql-13-capacity-units-7j.kql](kql-13-capacity-units-7j.kql) | Capacity Units sur 7 jours | Capacity planning |

### Catégorie 5 — Audits et compliance

| # | Fichier | Usage | Fréquence |
|---|---------|-------|-----------|
| KQL 14 | [kql-14-audit-changements-config-agw.kql](kql-14-audit-changements-config-agw.kql) | Modifications config AGW | Hebdomadaire |
| KQL 15 | [kql-15-verification-retention-logs.kql](kql-15-verification-retention-logs.kql) | Vérification rétention et complétude | Mensuel |

---

## Comment utiliser ces requêtes

### Dans le portail Azure

1. Ouvrir `law-a2i-network-prod` → **Logs**
2. Copier-coller la requête
3. Ajuster `ago(24h)` selon la fenêtre d'analyse
4. Cliquer **Run**

### Dans un Workbook

Insérer via **+ Add query** → coller le KQL → titre = nom du fichier.

### En alerte Azure Monitor

KQL 04 et KQL 08 sont conçues pour être utilisées comme règles d'alerte.

---

## Prérequis

- Workspace Log Analytics : `law-a2i-network-prod`
- Diagnostic Settings AGW activés (AccessLog + FirewallLog)
- Durée minimale de données : 24h pour `ago(24h)`, 7j pour `ago(7d)`

---

*Auteur : Doctor Kloud — version 1.0.0 — mai 2026*
