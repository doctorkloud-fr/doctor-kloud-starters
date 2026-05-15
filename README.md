# Doctor Kloud — Starter Kits

> **Production-ready starters** pour chaque guide Doctor Kloud.
> Testés en lab réel, corrigés par rapport à la spec, prêts à déployer.

[![GitHub Stars](https://img.shields.io/github/stars/doctorkloud-fr/doctor-kloud-starterkits?style=flat-square)](https://github.com/doctorkloud-fr/doctor-kloud-starterkits/stargazers)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat-square)](LICENSE)
[![Azure](https://img.shields.io/badge/Azure-IaC-0078D4?style=flat-square&logo=microsoftazure)](https://azure.microsoft.com)
[![Doctor Kloud](https://img.shields.io/badge/Doctor%20Kloud-guides-black?style=flat-square)](https://doctorkloud.fr)

---

##  Ce repo

Chaque guide Doctor Kloud donne naissance à un starter kit :
du code testé en lab réel, avec les bugs de la spec corrigés
et les workarounds documentés.

Pas du code théorique — du code qui a tourné sur un vrai tenant Azure.

---

##  Starter Kits disponibles

| Guide | Contenu | Chapitres couverts | Status |
|-------|---------|-------------------|--------|
| [🔵 Azure Application Gateway](./Azure%20Application%20Gateway/) | Bicep · KQL · Tests · Scripts PS | Ch.4 → Ch.19 + Annexes | ✅ Disponible |
| 🟡 Azure Front Door | Bicep · WAF · DR | — | 🔜 Bientôt |
| 🟡 Azure Firewall | Bicep · Rules · Monitoring | — | 🔜 Bientôt |
| 🟡 AKS + AGIC | Bicep · Ingress · WAF | — | 🔜 Bientôt |

---

##  Démarrage rapide

```bash
# Cloner le repo
git clone https://github.com/doctorkloud-fr/doctor-kloud-starterkits.git

# Naviguer vers le starter kit souhaité
cd "doctor-kloud-starterkits/Azure Application Gateway/iac-network"

# What-if avant tout déploiement (obligatoire)
az deployment group what-if \
  --resource-group  \
  --template-file modules/agw/main.bicep \
  --parameters environments/dev/lab.bicepparam

# Déployer
az deployment group create \
  --resource-group  \
  --template-file modules/agw/main.bicep \
  --parameters environments/dev/lab.bicepparam
```

---

## 📁 Structure
doctor-kloud-starterkits/
│
├── Azure Application Gateway/
│   ├── iac-network/              ← Bicep + pipeline CI/CD
│   ├── Bibliothèque KQL/         ← 15 requêtes production-ready
│   ├── Plan de tests T-01→T-15/  ← Suite de tests bash
│   └── Scripts PowerShell/       ← 5 scripts audit et diagnostic
│
├── Azure Front Door/             ← 🔜 Bientôt
└── Azure Firewall/               ← 🔜 Bientôt

---

##  Bugs documentés vs spec

Chaque starter kit documente les divergences entre la spec
du guide et la réalité Azure 2026. Ces corrections sont
intégrées directement dans le code.

Exemple pour Azure Application Gateway : **90+ bugs corrigés**,
dont des champs KQL inexistants, des commandes CLI non supportées,
et des sous-modules Bicep non rédigés dans la spec originale.

---

##  Contribution

Les PR sont bienvenues :

- Un bug trouvé → ouvrir une **issue** avec le label `bug-spec`
- Un fix → ouvrir une **PR** avec référence à l'issue
- Une amélioration → discussion ouverte bienvenue

---

## 📖 Les guides Doctor Kloud

Retrouve les guides complets sur **[doctorkloud.fr](https://doctorkloud.fr)**
