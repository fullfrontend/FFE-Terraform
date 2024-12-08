resource "digitalocean_project" "terraform_learn" {
  name        = "Learn Terraform"
  description = "Learning Project for Terraform"
  environment = "Development"
  purpose     = "Class project / Educational purposes"
  resources   = [
    digitalocean_droplet.cloud.urn,
    digitalocean_droplet.prod.urn,
  ]
}
