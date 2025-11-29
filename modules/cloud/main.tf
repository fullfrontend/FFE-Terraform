resource "digitalocean_droplet" "cloud" {
  image  = "ubuntu-24-04-x64"
  name   = "cloud"
  region = var.do_region
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    var.ssh_key.id
  ]


  user_data = templatefile("${path.root}/files/cloud-init.tpl", {
    volume-name = digitalocean_volume.cloud.name
    pubkey      = var.ssh_key.public_key
  })

}

