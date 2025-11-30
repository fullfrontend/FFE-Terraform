resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  is_prod          = var.app_env == "prod"
  cluster_name     = local.is_prod ? "${var.doks_name}-${random_id.cluster_name.hex}" : "minikube"
  root_domain      = var.root_domain
  n8n_host         = var.n8n_host != "" ? var.n8n_host : format("n8n.%s", local.root_domain)
  n8n_webhook_host = var.n8n_webhook_host != "" ? var.n8n_webhook_host : format("webhook.%s", local.root_domain)
  wp_host          = var.wp_host != "" ? var.wp_host : format("%s", local.root_domain)
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
}

module "k8s-config" {
  source          = "./modules/k8s-config"
  cluster_name    = local.cluster_name
  region          = var.doks_region
  do_token        = var.do_token
  is_prod         = local.is_prod
  kubeconfig_path = var.kubeconfig_path
  enable_cert_manager = local.is_prod

  enable_velero     = var.enable_velero
  velero_bucket     = var.velero_bucket
  velero_s3_url     = var.velero_s3_url
  velero_access_key = var.velero_access_key
  velero_secret_key = var.velero_secret_key

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

  host          = local.n8n_host
  webhook_host  = local.n8n_webhook_host
  db_host       = var.n8n_db_host
  db_port       = var.n8n_db_port
  db_name       = var.n8n_db_name
  db_user       = var.n8n_db_user
  db_password   = var.n8n_db_password
  chart_version = var.n8n_chart_version
}

module "wordpress" {
  source = "./modules/wordpress"

  host            = local.wp_host
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
