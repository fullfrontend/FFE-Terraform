resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  is_prod          = var.app_env == "prod"
  cluster_name     = local.is_prod ? "${var.doks_name}-${random_id.cluster_name.hex}" : "docker-desktop"
  root_domain      = var.root_domain
  n8n_host         = var.n8n_host != "" ? var.n8n_host : format("n8n.%s", local.root_domain)
  n8n_webhook_host = var.n8n_webhook_host != "" ? var.n8n_webhook_host : format("webhook.%s", local.root_domain)
  wp_host          = var.wp_host != "" ? var.wp_host : format("%s", local.root_domain)
  nextcloud_host   = var.nextcloud_host != "" ? var.nextcloud_host : format("cloud.%s", local.root_domain)
  mail_host        = var.mail_host != "" ? var.mail_host : format("mail.%s", local.root_domain)
  kubeconfig_path  = local.is_prod ? "${path.root}/.kube/config" : "~/.kube/config"
  velero_s3_url    = var.velero_s3_url != "" ? var.velero_s3_url : format("https://%s.digitaloceanspaces.com", var.doks_region)
  velero_dev_bucket   = var.velero_dev_bucket != "" ? var.velero_dev_bucket : "${local.cluster_name}-velero"
  velero_dev_host_path = "${path.root}/data/${local.velero_dev_bucket}"
  storage_class_name  = local.is_prod ? "" : (var.storage_class_name != "" ? var.storage_class_name : "hostpath")
  postgres_root_password = local.is_prod ? (var.postgres_root_password_prod != "" ? var.postgres_root_password_prod : var.postgres_root_password) : (var.postgres_root_password_dev != "" ? var.postgres_root_password_dev : var.postgres_root_password)
  mariadb_root_password  = local.is_prod ? (var.mariadb_root_password_prod != "" ? var.mariadb_root_password_prod : var.mariadb_root_password) : (var.mariadb_root_password_dev != "" ? var.mariadb_root_password_dev : var.mariadb_root_password)
  n8n_db_password        = local.is_prod ? (var.n8n_db_password_prod != "" ? var.n8n_db_password_prod : var.n8n_db_password) : (var.n8n_db_password_dev != "" ? var.n8n_db_password_dev : var.n8n_db_password)
  wp_db_password         = local.is_prod ? (var.wp_db_password_prod != "" ? var.wp_db_password_prod : var.wp_db_password) : (var.wp_db_password_dev != "" ? var.wp_db_password_dev : var.wp_db_password)
  nextcloud_db_password  = local.is_prod ? (var.nextcloud_db_password_prod != "" ? var.nextcloud_db_password_prod : var.nextcloud_db_password) : (var.nextcloud_db_password_dev != "" ? var.nextcloud_db_password_dev : var.nextcloud_db_password)
  mailu_db_password      = local.is_prod ? (var.mailu_db_password_prod != "" ? var.mailu_db_password_prod : var.mailu_db_password) : (var.mailu_db_password_dev != "" ? var.mailu_db_password_dev : var.mailu_db_password)
  mailu_secret_key       = local.is_prod ? (var.mailu_secret_key_prod != "" ? var.mailu_secret_key_prod : var.mailu_secret_key) : (var.mailu_secret_key_dev != "" ? var.mailu_secret_key_dev : var.mailu_secret_key)
  mailu_admin_password   = local.is_prod ? (var.mailu_admin_password_prod != "" ? var.mailu_admin_password_prod : var.mailu_admin_password) : (var.mailu_admin_password_dev != "" ? var.mailu_admin_password_dev : var.mailu_admin_password)
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

  storage_class_name = local.storage_class_name

  postgres_image           = var.postgres_image
  postgres_storage_size    = var.postgres_storage_size
  postgres_root_password   = local.postgres_root_password
  postgres_app_credentials = var.postgres_app_credentials

  mariadb_image           = var.mariadb_image
  mariadb_storage_size    = var.mariadb_storage_size
  mariadb_root_password   = local.mariadb_root_password
  mariadb_app_credentials = var.mariadb_app_credentials
}

module "n8n" {
  source = "./modules/n8n"
  depends_on = [module.k8s-config]

  host          = local.n8n_host
  webhook_host  = local.n8n_webhook_host
  db_host       = var.n8n_db_host
  db_port       = var.n8n_db_port
  db_name       = var.n8n_db_name
  db_user       = var.n8n_db_user
  db_password   = local.n8n_db_password
  chart_version = var.n8n_chart_version
}

module "wordpress" {
  source = "./modules/wordpress"
  depends_on = [module.k8s-config]

  host            = local.wp_host
  tls_secret_name = var.wp_tls_secret_name
  db_host         = var.wp_db_host
  db_port         = var.wp_db_port
  db_name         = var.wp_db_name
  db_user         = var.wp_db_user
  db_password     = local.wp_db_password
  replicas        = var.wp_replicas
  storage_size    = var.wp_storage_size
  image           = var.wp_image
}

module "nextcloud" {
  source     = "./modules/nextcloud"
  depends_on = [module.k8s-config]

  host            = local.nextcloud_host
  tls_secret_name = var.nextcloud_tls_secret_name
  db_host         = var.nextcloud_db_host
  db_port         = var.nextcloud_db_port
  db_name         = var.nextcloud_db_name
  db_user         = var.nextcloud_db_user
  db_password     = local.nextcloud_db_password
  replicas        = var.nextcloud_replicas
  storage_size    = var.nextcloud_storage_size
  chart_version   = var.nextcloud_chart_version
}

module "mailu" {
  source     = "./modules/mailu"
  depends_on = [module.k8s-config]

  host              = local.mail_host
  domain            = local.root_domain
  tls_secret_name   = var.mailu_tls_secret_name
  db_host           = var.mailu_db_host
  db_port           = var.mailu_db_port
  db_name           = var.mailu_db_name
  db_user           = var.mailu_db_user
  db_password       = local.mailu_db_password
  secret_key        = local.mailu_secret_key
  admin_username    = var.mailu_admin_username
  admin_password    = local.mailu_admin_password
  chart_version     = var.mailu_chart_version
}
