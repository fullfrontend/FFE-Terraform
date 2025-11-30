# FFE Terraform

Infrastructure Terraform Full Front-End. Utilise `OpenToFu`.

Crée un cluster Kubernetes sur DigitalOcean.
Déploie plusieurs applications via Helm.

## Résumé court
Provisionne un cluster Kubernetes DigitalOcean (DOKS) avec OpenTofu/Helm, sépare stockage bloc (PVC) et objet (Spaces), et déploie les apps (WordPress MariaDB, n8n, CRM futur, Nextcloud, Mailu) derrière ingress, cert-manager et external-dns.

## Notes
- Bannir les images/charts Bitnami (licence payante) et privilégier les charts upstream/officiels.
- Domaine principal configurable via `root_domain` (ex: example.com) pour générer les FQDN des apps (n8n, webhook, WordPress…).

## Documentation

* Provider DigitalOcean : https://search.opentofu.org/provider/digitalocean/digitalocean/latest
* Provider Kubernetes : https://search.opentofu.org/provider/hashicorp/kubernetes/latest
* Provider Helm : https://search.opentofu.org/provider/hashicorp/helm/latest
