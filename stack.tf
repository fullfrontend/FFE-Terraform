resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  is_prod          = var.app_env == "prod"
  cluster_name     = local.is_prod ? "${var.doks_name}-${random_id.cluster_name.hex}" : "docker-desktop"
  root_domain      = var.root_domain
  kubeconfig_path  = local.is_prod ? "${path.root}/.kube/config" : "~/.kube/config"
  velero_s3_url    = var.velero_s3_url != "" ? var.velero_s3_url : format("https://%s.digitaloceanspaces.com", var.doks_region)
  storage_class_name  = var.storage_class_name
  analytics_domains        = length(var.analytics_domains) > 0 ? var.analytics_domains : [local.root_domain]
}

module "doks-cluster" {
  count            = local.is_prod ? 1 : 0
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
  velero_bucket       = var.velero_bucket
}

module "k8s-config" {
  source          = "./modules/k8s-config"
  cluster_name    = local.cluster_name
  region          = var.doks_region
  do_token        = var.do_token
  is_prod         = local.is_prod
  kubeconfig_path = local.kubeconfig_path
  enable_cert_manager = local.is_prod

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

module "n8n" {
  source = "./modules/n8n"
  depends_on = [module.k8s-config]

  host          = format("n8n.%s", local.root_domain)
  webhook_host  = format("webhook.%s", local.root_domain)
  db_host       = var.n8n_db_host
  db_port       = var.n8n_db_port
  db_name       = var.n8n_db_name
  db_user       = var.n8n_db_user
  db_password   = var.n8n_db_password
  chart_version = var.n8n_chart_version
}

module "wordpress" {
  source = "./modules/wordpress"
  depends_on = [module.k8s-config]

  host            = local.root_domain
  tls_secret_name = var.wp_tls_secret_name
  db_host         = var.wp_db_host
  db_port         = var.wp_db_port
  db_name         = var.wp_db_name
  db_user         = var.wp_db_user
  db_password     = var.wp_db_password
  replicas        = var.wp_replicas
  storage_size    = var.wp_storage_size
  image           = var.wp_image
}

module "nextcloud" {
  source     = "./modules/nextcloud"
  depends_on = [module.k8s-config]

  host            = format("cloud.%s", local.root_domain)
  tls_secret_name = var.nextcloud_tls_secret_name
  db_host         = var.nextcloud_db_host
  db_port         = var.nextcloud_db_port
  db_name         = var.nextcloud_db_name
  db_user         = var.nextcloud_db_user
  db_password     = var.nextcloud_db_password
  replicas        = var.nextcloud_replicas
  storage_size    = var.nextcloud_storage_size
  chart_version   = var.nextcloud_chart_version
}

module "mailu" {
  source     = "./modules/mailu"
  depends_on = [module.k8s-config]

  host              = format("mail.%s", local.root_domain)
  domain            = local.root_domain
  tls_secret_name   = var.mailu_tls_secret_name
  db_host           = var.mailu_db_host
  db_port           = var.mailu_db_port
  db_name           = var.mailu_db_name
  db_user           = var.mailu_db_user
  db_password       = var.mailu_db_password
  secret_key        = var.mailu_secret_key
  admin_username    = var.mailu_admin_username
  admin_password    = var.mailu_admin_password
  chart_version     = var.mailu_chart_version
}

module "analytics" {
  source     = "./modules/analytics"
  depends_on = [module.k8s-config]

  host            = format("insights.%s", local.root_domain)
  tls_secret_name = var.analytics_tls_secret_name
  domains         = local.analytics_domains
  admin_username  = var.analytics_admin_username
  admin_password  = var.analytics_admin_password
  chart_version   = var.analytics_chart_version
}
