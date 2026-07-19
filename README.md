<h1 align="center">FFE Terraform</h1>

<p align="center">
  <b><i>Déploiement complet d’une stack Kubernetes via OpenTofu/Helm</i></b><br />
  <b>🌐 <a href="https://fullfrontend.be">fullfrontend.be</a></b><br />
</p>

---

#### Contents

- **[About](#about)**
  - [Stack Overview](#stack-overview)
  - [Environments](#environments)
  - [Domains](#domains)
- **[Usage](#usage)**
  - [Prerequisites](#prerequisites)
  - [Secrets](#secrets)
  - [Quick Start](#quick-start)
  - [Configuration](#configuration)
- **[Modules](#modules)**
  - [Apps](#apps)
  - [Observability](#observability)
  - [Platform Security](#platform-security)
- **[License](#license)**
- **[Security](#security)**

---

## About
Stack Kubernetes complète, gérée en Infrastructure-as-Code avec OpenTofu + Helm. Le repo est conçu pour rester simple à opérer et 100% auto-hébergé (pas de services managés, pas de Bitnami).

### Stack Overview
- Ingress: Traefik en prod, nginx en dev (minikube)
- TLS: cert-manager (prod)
- DNS: external-dns (prod)
- Backups: Velero (prod: DO Spaces, dev: MinIO)
- Data: Postgres + MariaDB (stateful en PVC)

### Environments
- **prod**: DOKS, kubeconfig dans `./.kube/config`, cert-manager & external-dns actifs
- **dev**: cluster local (`~/.kube/config`), cert-manager & external-dns désactivés

### Domains
- Prod: `root_domain_prod` (défaut `fullfrontend.be`)
- Dev: `root_domain_dev` (défaut `fullfrontend.kube`)
- FQDN principaux dérivés de `root_domain`, avec les exceptions de staging indiquées :
  - WordPress: `<root_domain>`
  - WordPress Granges du Tilleul (staging): `grangesdutilleul.staging.fullfrontend.be`
  - Redirect staging: `staging.fullfrontend.be` → `https://fullfrontend.be`
  - n8n: `n8n.<root_domain>` + `webhook.<root_domain>`
  - Analytics: `insights.<root_domain>`
  - Sentry: `sentry.<root_domain>`
  - FRP server: `frp.<root_domain>` + dashboard `tunnels.<root_domain>` + tunnel HTTP `social.<root_domain>`
  - Registry: `registry.<root_domain>`
  - OpenCloud: `cloud.<root_domain>`

## Usage

### Prerequisites
- `age` et `sops`
- `tofu`, `helm`, `kubectl`
- `doctl` (prod)
- Exports requis: `SOPS_AGE_KEY_FILE`, `SOPS_AGE_RECIPIENTS`, `APP_ENV=dev|prod`

### Secrets
1. Générer la clé age: `bin/age-init.sh` puis exporter les variables.
2. Copier l’exemple: `cp secrets.tfvars.example secrets.tfvars` et remplir.
3. Chiffrer: `bin/sops-encrypt.sh secrets.tfvars secrets.tfvars.enc`.
4. Utiliser le wrapper tofu: `APP_ENV=... ./scripts/tofu-secrets.sh plan|apply`.

### Quick Start
1) `export APP_ENV=dev` (ou `prod`) et `export TF_VAR_app_env=$APP_ENV` si besoin.
2) `tofu init`.
3) Prod (cluster absent): `APP_ENV=prod ./scripts/tofu-secrets.sh apply -target=module.doks-cluster`.
4) Prod: récupérer le kubeconfig DO dans `./.kube/config` via `doctl kubernetes cluster kubeconfig save ...`.
5) Déployer: `APP_ENV=... ./scripts/tofu-secrets.sh apply` (ou `plan`).
6) Dev: minikube installe l’ingress nginx via la commande de launch.

### Configuration
Principaux toggles:
- `app_env`: `prod` / `dev`
- `enable_tls`: active TLS + redirect HTTPS
- `enable_velero`: backups Velero

Docs utiles:
- Contexte infra: [CONTEXT_INFRA.md](CONTEXT_INFRA.md)
- Règles IA: [docs/CONTEXT.md](docs/CONTEXT.md)
- Blog post: [INITIAL_BLOG_POST.md](INITIAL_BLOG_POST.md)

## Modules

### Apps
- WordPress (MariaDB + PVC principal, plus PVC privé de 1 GiB monté dans `/var/www/ffe-private-guides`, uploads PHP limités à 2 GiB)
- WordPress Granges du Tilleul en staging (même socle que `fullfrontend.be`, avec `APP_ENV=dev`, sans S3 ni cache, et SMTP dédié optionnel)

Convention : tout hostname sous `*.staging.fullfrontend.be` est un environnement applicatif DEV et doit recevoir `APP_ENV=dev`. Ces workloads peuvent être hébergés sur le cluster public DOKS pour bénéficier du DNS et de TLS sans devenir des environnements applicatifs de production.
- n8n (Postgres + Redis optionnel)
- Twenty CRM (optionnel)
- Analytics (Vince)
- Sentry (optionnel)
- FRP server (optionnel)
  Usage cible: `frpc` tourne sur le NAS et publie `social.<root_domain>` ainsi que d’autres tunnels HTTP
- OpenCloud (optionnel)
- Registry (Zot)

### Observability
- Prometheus + Grafana (kube-prometheus-stack)
- Dashboards: [grafana/dashboards/](grafana/dashboards/)

### Platform Security
- TLS via cert-manager en prod
- Secrets chiffrés (SOPS/age)

## License
Tout le dépôt est sous WTFPL (`LICENSE`). Aucune garantie ni support.

## Security
Pour signaler une vulnérabilité, suivre [SECURITY.md](SECURITY.md). Pas de secrets ni données sensibles dans les issues/PR.

- Domaine additionnel possible via OVH/external-dns: `he8us.be` avec redirect `(www.)he8us.be -> https://fullfrontend.be`.
