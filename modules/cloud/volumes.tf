resource "digitalocean_volume" "cloud" {
  region                  = var.do_region
  description             = "Volume storage for Cloud server"
  name                    = "cloud-data"
  size                    = 5
  initial_filesystem_type = "ext4"

  lifecycle {
    prevent_destroy = true
  }

}

resource "digitalocean_volume_attachment" "cloud" {
  droplet_id = digitalocean_droplet.cloud.id
  volume_id  = digitalocean_volume.cloud.id
}
