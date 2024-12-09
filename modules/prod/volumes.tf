resource "digitalocean_volume" "prod" {
  region                  = var.do_region
  description             = "Volume storage for production server"
  name                    = "prod-data"
  size                    = 5
  initial_filesystem_type = "ext4"

  lifecycle {
    prevent_destroy = true
  }
}

resource "digitalocean_volume_attachment" "prod" {
  droplet_id = digitalocean_droplet.prod.id
  volume_id  = digitalocean_volume.prod.id
}
