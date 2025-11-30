# FFE Terraform

Infrastructure Terraform Full Front-End avec OpenTofu, pour provisionner un cluster Kubernetes DigitalOcean (DOKS) et déployer les apps via Helm.

## Ce que fait ce projet
- Provision infra Kubernetes (DOKS en prod, cluster local en dev, ex: docker-desktop) avec Traefik, external-dns, cert-manager (prod), Velero.
- Sépare stockage bloc (PVC) et objet (Spaces/MinIO).
- Déploie les apps : WordPress (MariaDB), n8n (Postgres), CRM futur, Nextcloud, Mailu.

## Démarrage rapide pour un dev
1) Choisir l’env : `export APP_ENV=dev` (cluster local/docker-desktop) ou `export APP_ENV=prod` (DOKS).  
2) `terraform init && terraform apply`.  
   - Dev : kubeconfig `~/.kube/config` pointant sur votre cluster local (docker-desktop), Velero optionnel avec MinIO local `./data/<velero_dev_bucket>` (git-ignoré).  
   - Prod : cluster DOKS créé, kubeconfig `${path.root}/.kube/config`, Velero activé automatiquement avec bucket DO Spaces auto-créé, cert-manager activé.
3) Ajuster les variables (DNS `root_domain`, DB creds, hosts applicatifs) dans `variable.tf`/`terraform.tfvars` si nécessaire.

## Domaines par défaut
- WordPress : `<root_domain>`
- n8n : `n8n.<root_domain>` + `webhook.<root_domain>`
- Nextcloud : `cloud.<root_domain>`
- Mailu : `mail.<root_domain>` + MX/SPF/DKIM/DMARC

## Bonnes pratiques
- Pas de charts Bitnami (licence payante).
- Ajout d’app : module dédié (namespace `apps`), ingress Traefik, entrées DB dans `postgres_app_credentials`/`mariadb_app_credentials` (création manuelle si DB déjà en place).
- Accès DB : préférez un `kubectl port-forward` ponctuel.
  - Postgres : `kubectl port-forward svc/postgres 5432:5432 -n data`
  - MariaDB : `kubectl port-forward svc/mariadb 3306:3306 -n data`

## Documentation
- Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
- Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
- Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest
