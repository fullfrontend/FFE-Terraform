resource "digitalocean_project" "terraform_learn" {
  name        = "Full Front-End"
  description = "Web stack for Website and Automation"
  environment = "Production"
  purpose     = "Website or Blog"
  resources = [
    module.doks-cluster.urns.cluster

  ]
}

resource "random_id" "cluster_name" {
  byte_length = 5
}

locals {
  cluster_name = "${var.doks_name}-${random_id.cluster_name.hex}"
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
}