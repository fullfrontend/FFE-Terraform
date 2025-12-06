# Contribuer à FFE Terraform

Merci d’aider le projet ! Tout est sous WTFPL ; en contribuant vous acceptez cette licence.

## Avant de commencer
- Outils : `age`, `sops`, `tofu`/`helm`/`kubectl`, `doctl` (prod), `mkcert` optionnel pour TLS dev.
- Secrets : aucun secret en clair. Utiliser SOPS/age (`bin/age-init.sh`, `bin/sops-encrypt.sh`) ou `TF_VAR_*`.
- Environnement : préciser `APP_ENV=dev|prod` dans vos issues/PR et le contexte (cluster local ou DOKS).
- Charts/images : pas de Bitnami. Préférer charts officiels/communautaires compatibles.

## Workflow local
1) `export APP_ENV=dev` (ou `prod`) et `export TF_VAR_app_env=$APP_ENV` si nécessaire.  
2) `tofu init`.  
3) Lancer un plan : `APP_ENV=dev ./scripts/tofu-secrets.sh plan` (le wrapper gère le decrypt/cleanup).  
4) Pour la prod, si besoin de créer le cluster DOKS : `APP_ENV=prod ./scripts/tofu-secrets.sh apply -target=module.doks-cluster`.

## Style et structure
- Un module par application (namespace `apps/<app>`), séparation bloc/objet respectée.
- Commentaires multi-lignes si besoin :
  ```
  /*
      Your comment here
  */
  ```
- Grafana : JSON propre, pas de données sensibles, idempotent pour l’import.

## Checklist PR
- [ ] Pas de secrets (ni dans le code, ni dans les outputs).
- [ ] Pas de chart/image Bitnami.
- [ ] `tofu plan` (ou tests/lint pertinents) fourni avec `APP_ENV` indiqué.
- [ ] Docs mises à jour si nécessaire (README/CONTEXT/monitoring/Grafana).
- [ ] Licence : contributions sous WTFPL (`LICENSE`).

## Code de conduite
Merci de respecter le [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md). Problème ? Ouvrez une issue en le signalant ou contactez les mainteneurs via les issues.
