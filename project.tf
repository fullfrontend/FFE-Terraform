resource "digitalocean_project" "terraform_learn" {
  name        = "Full Front-End"
  description = "Web stack for Website and Automation"
  environment = "Production"
  purpose     = "Website or blog"
  resources = [
    module.doks-cluster.urns.cluster

  ]
}

resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  cluster_name       = "${var.doks_name}-${random_id.cluster_name.hex}"
  root_domain        = var.root_domain
  n8n_host           = var.n8n_host != "" ? var.n8n_host : format("n8n.%s", local.root_domain)
  n8n_webhook_host   = var.n8n_webhook_host != "" ? var.n8n_webhook_host : format("webhook.%s", local.root_domain)
  wp_host            = var.wp_host != "" ? var.wp_host : format("www.%s", local.root_domain)
}


module "doks-cluster" {
  source         = "./modules/doks-cluster"
  name           = local.cluster_name
  region         = var.doks_region
  node_size      = var.doks_node_size
  pool_min_count = 3
  pool_max_count = 5
  write_kubeconfig = true
}


module "k8s-config" {
  source = "./modules/k8s-config"
  cluster_id = module.doks-cluster.cluster_id
  cluster_name = module.doks-cluster.cluster_name
  do_token = var.do_token

  enable_velero   = var.enable_velero
  velero_bucket   = var.velero_bucket
  velero_region   = var.velero_region
  velero_s3_url   = var.velero_s3_url
  velero_access_key = var.velero_access_key
  velero_secret_key = var.velero_secret_key
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

  host           = local.wp_host
  tls_secret_name = var.wp_tls_secret_name
  db_host        = var.wp_db_host
  db_port        = var.wp_db_port
  db_name        = var.wp_db_name
  db_user        = var.wp_db_user
  db_password    = var.wp_db_password
  replicas       = var.wp_replicas
  storage_size   = var.wp_storage_size
  image          = var.wp_image
}
