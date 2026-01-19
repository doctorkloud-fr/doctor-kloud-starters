# Azure Doctor Starters

Starters opinionated pour démarrer vite et démarrer proprement. Un starter n’est pas une démo. C’est une base de départ structurée, avec des choix assumés et des points d’extension explicites.

## What you will find here

- des bases projet prêtes à cloner,
- une structure stable (infra, ops, docs),
- des safe defaults et des conventions cohérentes,
- une section "Customization" qui dit quoi adapter et où.

## When to use

Utilise un starter si tu veux :
- bootstrap un projet avec une baseline claire,
- éviter de redécider les mêmes conventions à chaque nouveau repo,
- converger vers une structure standard pour une équipe.

## When NOT to use

N’utilise pas un starter si tu cherches :
- un lab guidé pas à pas,
- une démo courte orientée pédagogie,
- un exemple minimaliste en un fichier.

Dans ce cas, va vers `azure-doctor-labs`.

## Starters catalog

| Starter | Purpose | Stack | Status |
| --- | --- | --- | --- |
| `entra-conditional-access-automation/` | Automatiser la création de policies CA (MFA, roles, baselines) | PowerShell, Microsoft Graph | Planned |
| `landing-zone-baseline/` | Baseline de gouvernance et structure (naming, tags, policy, RBAC) | Bicep ou Terraform | Planned |
| `observability-baseline/` | Baseline logs, alerts et dashboards | KQL, Azure Monitor | Planned |

Les starters arrivent progressivement. Le premier objectif est d’en publier peu, mais impeccables.

## Quality standard

Chaque starter doit répondre à quatre questions :
- À quoi ça sert ?
- Quand l’utiliser et quand l’éviter ?
- Comment l’exécuter sans surprise ?
- Quelles sont les limites et les trade-offs ?

Si ces réponses ne tiennent pas dans le README, le starter n’est pas prêt.

## Versioning

Quand un starter devient une base réutilisée dans plusieurs contenus ou projets, nous publions des releases.
Breaking changes annoncés dans les release notes.

## License

Voir `LICENSE` dans ce repo.

## Hub

Le hub de l’Organization est ici : `azure-doctor/azure-doctor`.
