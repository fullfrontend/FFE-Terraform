resource "random_id" "cluster_name" {
  byte_length = 5
}

/*
    Global toggles:
    - prod = DOKS with managed infra
    - dev  = local kube (ex: docker-desktop)
*/
locals {
  is_prod            = var.app_env == "prod"
  cluster_name       = local.is_prod ? "${var.doks_name}-${random_id.cluster_name.hex}" : "docker-desktop"
  root_domain        = local.is_prod ? var.root_domain_prod : var.root_domain_dev
  kubeconfig_path    = local.is_prod ? "${path.root}/.kube/config" : "~/.kube/config"
  velero_s3_url      = var.velero_s3_url != "" ? var.velero_s3_url : format("https://%s.digitaloceanspaces.com", var.doks_region)
  storage_class_name = var.storage_class_name
  analytics_domains  = length(var.analytics_domains) > 0 ? var.analytics_domains : [local.root_domain]
  ingress_class_name = local.is_prod ? "traefik" : "nginx"
  postgres_app_map   = { for app in var.postgres_app_credentials : app.name => app }
  mariadb_app_map    = { for app in var.mariadb_app_credentials : app.name => app }
}

/*
    Prod cluster: DOKS + project attachment + Spaces bucket for Velero
    Disabled in dev (local cluster)
*/
module "doks-cluster" {
  count            = local.is_prod && var.create_doks_cluster ? 1 : 0
  source           = "./modules/doks-cluster"
  name             = local.cluster_name
  region           = var.doks_region
  node_size        = var.doks_node_size
  pool_min_count   = 3
  pool_max_count   = 5
  write_kubeconfig = true

  project_name        = "Full Front-End"
  project_description = "Web stack for Website and Automation"
  project_environment = "Production"
  project_purpose     = "Website or blog"
}
//*/


/*
    Cluster services and data plane:
    - Traefik, cert-manager, external-dns (prod)
    - Velero (Spaces/MinIO)
    - Namespaces infra/data
    - Postgres/MariaDB stateful sets
*/
module "k8s-config" {
  source               = "./modules/k8s-config"
  cluster_name         = local.cluster_name
  region               = var.doks_region
  root_domain          = local.root_domain
  extra_domain_filters = var.extra_domain_filters
  do_token             = var.do_token
  is_prod              = local.is_prod
  kubeconfig_path      = local.kubeconfig_path
  enable_cert_manager  = local.is_prod
  acme_email           = var.acme_email
  enable_tls           = var.enable_tls

  enable_velero     = true
  velero_bucket     = var.velero_bucket
  velero_s3_url     = local.velero_s3_url
  velero_access_key = var.velero_access_key
  velero_secret_key = var.velero_secret_key
  minio_access_key  = var.minio_access_key
  minio_secret_key  = var.minio_secret_key

  storage_class_name = local.storage_class_name

  postgres_image           = var.postgres_image
  postgres_storage_size    = var.postgres_storage_size
  postgres_root_password   = var.postgres_root_password
  postgres_app_credentials = var.postgres_app_credentials

  mariadb_image           = var.mariadb_image
  mariadb_storage_size    = var.mariadb_storage_size
  mariadb_root_password   = var.mariadb_root_password
  mariadb_app_credentials = var.mariadb_app_credentials
}
//*/

/*
    Monitoring (kube-prometheus-stack + Grafana)
*/
module "monitoring" {
  count      = var.enable_monitoring ? 1 : 0
  source     = "./modules/monitoring"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  is_prod                      = local.is_prod
  enable_kube_prometheus_stack = true
  grafana_host                 = format("monitoring.%s", local.root_domain)
  grafana_admin_user           = var.grafana_admin_user
  grafana_admin_password       = var.grafana_admin_password
}
//*/

/*
    Issuer Let's Encrypt (runs after cert-manager install)
*/
module "cert_manager_issuer" {
  source     = "./modules/cert-manager-issuer"
  depends_on = [module.k8s-config]

  is_prod         = local.is_prod
  acme_email      = var.acme_email
  kubeconfig_path = local.kubeconfig_path
}
//*/



/*
    App: n8n (external Postgres)
*/
module "n8n" {
  count      = var.enable_n8n ? 1 : 0
  source     = "./modules/n8n-ffe"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = format("n8n.%s", local.root_domain)
  webhook_host       = format("webhook.%s", local.root_domain)
  db_host            = module.k8s-config.postgres_service_fqdn
  db_port            = var.n8n_db_port
  db_name            = local.postgres_app_map["n8n-ffe"].db_name
  db_user            = local.postgres_app_map["n8n-ffe"].user
  db_password        = local.postgres_app_map["n8n-ffe"].password
  chart_version      = var.n8n_chart_version
  ingress_class_name = local.ingress_class_name
}
//*/


/*
    App: WordPress (external MariaDB, PVC wp-content)
*/
module "wordpress" {
  source     = "./modules/ffe-website"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = local.root_domain
  tls_secret_name    = var.wp_tls_secret_name
  db_host            = module.k8s-config.mariadb_service_fqdn
  db_port            = var.wp_db_port
  db_name            = local.mariadb_app_map["ffe-website"].db_name
  db_user            = local.mariadb_app_map["ffe-website"].user
  db_password        = local.mariadb_app_map["ffe-website"].password
  replicas           = var.wp_replicas
  storage_size       = var.wp_storage_size
  image              = var.wp_image
  ingress_class_name = local.ingress_class_name
  dockerhub_user     = var.dockerhub_user
  dockerhub_pat      = var.dockerhub_pat
  dockerhub_email    = var.dockerhub_email
  velero_namespace   = module.k8s-config.velero_namespace
  as3_provider       = var.wp_as3_provider
  as3_access_key     = var.wp_as3_access_key
  as3_secret_key     = var.wp_as3_secret_key
  mail_from          = var.wp_mail_from
  mail_from_name     = var.wp_mail_from_name
  smtp_host          = var.wp_smtp_host
  smtp_port          = var.wp_smtp_port
  smtp_ssl           = var.wp_smtp_ssl
  smtp_auth          = var.wp_smtp_auth
  smtp_user          = var.wp_smtp_user
  smtp_pass          = var.wp_smtp_pass
  wp_lang            = var.wp_lang
}
//*/


/*
    App: Nextcloud (external Postgres, PVC data)
*/
module "nextcloud" {
  # Nextcloud désactivé (sera remis en ligne plus tard)
  count      = 0
  source     = "./modules/nextcloud-ffe"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = format("cloud.%s", local.root_domain)
  tls_secret_name    = var.nextcloud_tls_secret_name
  db_host            = module.k8s-config.postgres_service_fqdn
  db_port            = var.nextcloud_db_port
  db_name            = local.postgres_app_map["nextcloud-ffe"].db_name
  db_user            = local.postgres_app_map["nextcloud-ffe"].user
  db_password        = local.postgres_app_map["nextcloud-ffe"].password
  replicas           = var.nextcloud_replicas
  storage_size       = var.nextcloud_storage_size
  chart_version      = var.nextcloud_chart_version
  ingress_class_name = local.ingress_class_name
}
//*/


/*
    App: Mailu (external Postgres, PVC maildir/config)
*/
module "mailu" {
  # Mailu désactivé (sera remis en ligne plus tard)
  count      = 0
  source     = "./modules/mailu-ffe"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = format("mail.%s", local.root_domain)
  domain             = local.root_domain
  tls_secret_name    = var.mailu_tls_secret_name
  db_host            = module.k8s-config.postgres_service_fqdn
  db_port            = var.mailu_db_port
  db_name            = local.postgres_app_map["mailu-ffe"].db_name
  db_user            = local.postgres_app_map["mailu-ffe"].user
  db_password        = local.postgres_app_map["mailu-ffe"].password
  secret_key         = var.mailu_secret_key
  admin_username     = var.mailu_admin_username
  admin_password     = var.mailu_admin_password
  chart_version      = var.mailu_chart_version
  ingress_class_name = local.ingress_class_name
}
//*/


/*
    App: Vince analytics (ingress + admin bootstrap)
*/
module "analytics" {
  source     = "./modules/analytics-ffe"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = format("insights.%s", local.root_domain)
  tls_secret_name    = var.analytics_tls_secret_name
  domains            = local.analytics_domains
  admin_username     = var.analytics_admin_username
  admin_password     = var.analytics_admin_password
  chart_version      = var.analytics_chart_version
  ingress_class_name = local.ingress_class_name
}
//*/



/*
    Private OCI/Docker registry (zot)
*/
module "registry" {
  source     = "./modules/registry"
  depends_on = [module.k8s-config, module.cert_manager_issuer]

  host               = format("registry.%s", local.root_domain)
  tls_secret_name    = "registry-tls"
  storage_size       = "20Gi"
  htpasswd_entry     = var.registry_htpasswd
  ingress_class_name = local.ingress_class_name
  storage_backend    = var.registry_storage_backend
  s3_endpoint        = var.registry_s3_endpoint
  s3_region          = var.registry_s3_region
  s3_bucket          = var.registry_s3_bucket
  s3_access_key      = var.registry_s3_access_key
  s3_secret_key      = var.registry_s3_secret_key
  s3_secure          = var.registry_s3_secure
  enable_tls         = var.enable_tls
}
//*/
