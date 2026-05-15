# Suite de tests AGW A2i — T-01 à T-15

> Tests de validation post-déploiement pour `agw-a2i-web-dev-westeu`.
> Adaptations lab documentées vs spec Doctor Kloud.

---

## Index des tests

| ID | Titre | Catégorie | Ref. chapitre | Pathologie | Script |
|----|-------|-----------|---------------|------------|--------|
| T-01 | AGW Provisioning State = Succeeded | Smoke | Ch.4, Ch.7 | — | [T-01](smoke/T-01-provisioning-state.sh) |
| T-02 | Public IP Standard zone-redundante | Smoke | Ch.4, Ch.15 | P3, P4 | [T-02](smoke/T-02-public-ip-standard.sh) |
| T-03 | Listeners HTTPS répondent à HEAD | Smoke | Ch.5 | — | [T-03](smoke/T-03-https-listeners.sh) |
| T-04 | Backend pools en état Healthy | Smoke | Ch.6 | P5, P6 | [T-04](smoke/T-04-backend-health.sh) |
| T-05 | Multi-site routing par Hostname | Functional | Ch.5, Ch.18 | — | [T-05](smoke/T-05-multi-site-routing.sh) |
| T-06 | Redirect HTTP→HTTPS retourne 301 | Functional | Ch.5 | P7 | [T-06](smoke/T-06-redirect-http-https.sh) |
| T-07 | Header X-Forwarded-Proto = https | Functional | Ch.5 | — | [T-07](smoke/T-07-x-forwarded-proto.sh) |
| T-08 | Custom probe /health = 200 | Functional | Ch.6 | P5 | [T-08](smoke/T-08-custom-probe-health.sh) |
| T-09 | TLS 1.2 minimum imposé | Functional | Ch.9 | P10 | [T-09](smoke/T-09-tls-minimum.sh) |
| T-10 | Tenue à 80% du pic — 10 min | Performance | Ch.10 | — | ⏭️ SKIP |
| T-11 | Latence P95 < 500ms | Performance | Ch.10, Ch.12 | — | [T-11](smoke/T-11-latence-p95-kql.md) |
| T-12 | Bascule Front Door < 60s | DR | Ch.15 | — | ⏭️ SKIP |
| T-13 | Autoscale AGW DR < 10 min | DR | Ch.10, Ch.15 | — | ⏭️ SKIP |
| T-14 | WAF bloque SQL injection | Security | Ch.9 | P9 | [T-14](smoke/T-14-waf-sqli-block.sh) |
| T-15 | Rotation certificat Key Vault | Security | Ch.11 | P13 | [T-15](smoke/T-15-cert-rotation.sh) |

---

## Lancer les tests

```bash
# Tous les tests
bash tests/scripts/run-all-tests.sh

# Un test spécifique
bash tests/smoke/T-01-provisioning-state.sh

# Smoke tests uniquement
for t in tests/smoke/T-0{1,2,3,4}.sh; do bash $t; done
```

---

## Tests skippés en lab

| ID | Raison |
|----|--------|
| T-10 | Azure Load Testing incompatible avec Cloud Shell MSI (Bug #70) |
| T-12 | Front Door supprimé après captures Ch.15 |
| T-13 | AGW DR West US 3 non créée en lab (Bug #105) |

---

## Adaptations lab vs spec

| Test | Adaptation |
|------|------------|
| T-03, T-05, T-06 | `--resolve HOST:PORT:IP` — DNS fictif non résolvable (Bug #139) |
| T-04 | `backendAddressPools` en camelCase (Bug #140) |
| T-11 | KQL uniquement — pas de script bash |
| T-15 | Capture thumbprint avant rotation — validation manuelle 4-24h après |

---

*Auteur : Doctor Kloud — version 1.0.0 — mai 2026*
