# Dashboards Grafana custom

Emplacement des dashboards prêts à importer dans Grafana.

## Dashboards
- `infra-apps-health.json` — Vue santé infra/apps/ingress : stat readiness pour WordPress/n8n/Nextcloud, Traefik, Postgres/MariaDB, taux 5xx Traefik, challenges cert-manager en erreur (15m), top PVC (utilisation %), CPU/mémoire nœuds.

## Import dans Grafana
1) Aller dans Grafana → Dashboards → New → Import.
2) Charger le fichier JSON depuis ce répertoire.
3) Sélectionner la datasource Prometheus si demandé.
4) Ajuster le dossier/slug si besoin. Plus de dashboards viendront s’ajouter ici.
