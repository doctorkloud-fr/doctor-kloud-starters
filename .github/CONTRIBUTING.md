# Contributing to Doctor Kloud Starter Kits

Merci de contribuer ! Ce repo est maintenu par la communauté Doctor Kloud.

---

## Comment contribuer

### Signaler un bug de spec

1. Ouvre une **issue**
2. Utilise le label `bug-spec`
3. Décris :
   - Le chapitre concerné (ex: Ch.12)
   - Ce que dit la spec
   - Ce que tu observes en réalité Azure
   - La version Azure CLI / az bicep utilisée

### Proposer un fix

1. Fork le repo
2. Crée une branche : `fix/bug-XX-description`
3. Commite avec le format : `fix(agw): correct BackendPoolName_s to backendPoolName_s (Bug #79)`
4. Ouvre une **Pull Request** avec référence à l'issue

### Ajouter un starter kit

1. Crée un dossier `Azure <Service>/`
2. Inclus un `README.md` avec la même structure que les starters existants
3. Ouvre une PR avec le label `new-starter`

---

## Format des commits
type(scope): description courte
Types : feat | fix | docs | ci | refactor
Scope : agw | kql | tests | scripts | bicep

---

## Code de conduite

Sois respectueux, constructif, et précis.
Les issues sans reproduction sont ignorées.

---

*Doctor Kloud — [doctorkloud.fr](https://doctorkloud.fr)*
