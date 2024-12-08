resource "digitalocean_droplet" "prod" {
  image    = "ubuntu-24-04-x64"
  name     = "prod"
  region   = var.do_region
  size     = "s-1vcpu-512mb-10gb"
  ssh_keys = [
    data.digitalocean_ssh_key.terraform.id
  ]
  volume_ids = [digitalocean_volume.prod.id]

}

resource "digitalocean_volume" "prod" {
  region                  = var.do_region
  description             = "Volume storage for production server"
  name                    = "prod"
  size                    = 5
  initial_filesystem_type = "ext4"

  lifecycle {
    prevent_destroy = true
  }
}
