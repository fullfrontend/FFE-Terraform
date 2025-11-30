# FFE Terraform

Infrastructure Terraform Full Front-End avec OpenTofu, pour provisionner un cluster Kubernetes DigitalOcean (DOKS) et déployer les apps via Helm.

## Résumé
- Provision Kubernetes DOKS + stack infra (Traefik, cert-manager, external-dns, Velero).
- Séparation stockage bloc (PVC) vs objet (Spaces).
- Apps cibles : WordPress (MariaDB), n8n (Postgres), CRM futur, Nextcloud, Mailu.
- Environnement : `APP_ENV` (`prod` par défaut, `dev` = minikube). En `dev`, pas de création DOKS ni cert-manager ; kubeconfig utilisé = `~/.kube/config`. En `prod`, kubeconfig généré dans `${path.root}/.kube/config`.

## Domaines (par défaut)
- WordPress : `<root_domain>` (override via `wp_host`)
- n8n : `n8n.<root_domain>` + webhooks `webhook.<root_domain>` (override via `n8n_host` / `n8n_webhook_host`)
- Nextcloud : `cloud.<root_domain>`
- Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC
- Domaine principal configurable via `root_domain` (ex: fullfrontend.test).

## Règles et bonnes pratiques
- Bannir les images/charts Bitnami (licence payante) : privilégier charts upstream/officiels.
- Choix env : exporter `APP_ENV=dev` pour viser minikube (kubeconfig `~/.kube/config`), `APP_ENV=prod` pour DOKS (kubeconfig `${path.root}/.kube/config` généré).
- Exemple d’export pour Terraform : `export APP_ENV=dev; export TF_VAR_app_env=$APP_ENV`
- Velero toujours activé en prod (bucket DO Spaces auto-créé) ; en dev, activation optionnelle via `enable_velero` avec MinIO sur hostPath local (`/tmp/velero-dev` par défaut).
- Ajout d’une app en prod : module dédié (namespace `apps`), ingress Traefik, entrée DB dans `postgres_app_credentials`/`mariadb_app_credentials`, créer DB+user manuellement si Postgres/MariaDB tournent déjà (init non rejoué). external-dns/cert-manager gèrent DNS/ACME dès l’ingress appliqué.
- Accès DB sécurisé (pour création/migration) : privilégier le kube-port-forwarding ponctuel plutôt qu’un panel web ; arrêter le port-forward une fois l’opération terminée.
  - Postgres : `kubectl port-forward svc/postgres 5432:5432 -n data`
  - MariaDB : `kubectl port-forward svc/mariadb 3306:3306 -n data`

## Documentation
- Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
- Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
- Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest
