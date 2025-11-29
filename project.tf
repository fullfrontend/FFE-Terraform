resource "digitalocean_project" "terraform_learn" {
    #Dropletss and volumes
    module.cloud-server.urns.droplet,
    module.cloud-server.urns.volume,

    module.prod-server.urns.droplet,
    module.prod-server.urns.volume,

    #Spaces
  name        = "Full Front-End"
  description = "Web stack for Website and Automation"
  environment = "Production"
  purpose     = "Website or Blog"
  resources = [

  ]
}

module "prod-server" {
  source = "./modules/prod"
  ssh_key = data.digitalocean_ssh_key.terraform
  do_region = var.do_region
}


module "cloud-server" {
  source = "./modules/cloud"
  ssh_key = data.digitalocean_ssh_key.terraform
  do_region = var.do_region
}
