resource "digitalocean_droplet" "prod" {
  image    = "ubuntu-24-04-x64"
  name     = "prod"
  region   = var.do_region
  size     = "s-1vcpu-1gb"
  ssh_keys = [
    var.ssh_key.id
  ]

  user_data = templatefile("../../files/cloud-init.tpl", {
    volume-name = digitalocean_volume.prod.name
    pubkey      = var.ssh_key.public_key
  })


}

