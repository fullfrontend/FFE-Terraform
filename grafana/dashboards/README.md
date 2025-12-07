# Dashboards Grafana custom

Emplacement des dashboards prêts à importer dans Grafana.

## Dashboards
- `infra-apps-health.json` — Vue santé infra/apps/ingress : stat readiness pour WordPress/n8n/Nextcloud, Traefik, Postgres/MariaDB, taux 5xx Traefik, challenges cert-manager en erreur (15m), top PVC (utilisation %), CPU/mémoire nœuds.

## Import initial (manuel, une fois)
1) Grafana → Dashboards → New → Import.
2) Choisir le fichier JSON depuis ce répertoire (`infra-apps-health.json`).
3) Sélectionner la datasource Prometheus si demandé.
4) Ajuster dossier/slug si besoin.

## Export/MAJ automatique (après modif dans Grafana)
1) Mettre vos identifiants Grafana dans `.env.local` (cf. `.env.local.example`).
2) Assurez-vous que Grafana est joignable (par ex. `GRAFANA_URL=https://monitoring...`).
3) Lancer `./scripts/export-grafana-dashboards.sh`.
   - Exporte chaque dashboard dont le titre correspond à un fichier JSON local, anonymise (supprime uid/id/slug/url/version) et écrase le fichier.
   - Prérequis : `curl`, `jq`, `python3`.
4) Pour pousser les dashboards locaux vers Grafana : `./scripts/update-grafana-dashboards.sh` (demande confirmation pour écraser ceux du même titre).
