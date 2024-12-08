resource "digitalocean_droplet" "cloud" {
  image    = "ubuntu-24-04-x64"
  name     = "cloud"
  region   = var.do_region
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
}
resource "digitalocean_volume" "cloud" {
  region                  = var.do_region
  description             = "Volume storage for Cloud server"
  name                    = "prod"
  size                    = 5
  initial_filesystem_type = "ext4"

  lifecycle {
    prevent_destroy = true
  }
}
