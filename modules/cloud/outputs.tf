output "urns" {
  value = {
    droplet : digitalocean_droplet.cloud.urn,
    volume : digitalocean_volume.cloud.urn,
    spaces : []
  }
}
