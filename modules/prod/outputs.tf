output "urns" {
  value = {
    droplet : digitalocean_droplet.prod.urn,
    volume : digitalocean_volume.prod.urn
    spaces : [
      digitalocean_spaces_bucket.website-public.urn,
      digitalocean_spaces_bucket.website-backup.urn,
      digitalocean_spaces_bucket.mautic-public.urn,
      digitalocean_spaces_bucket.mautic-backup.urn,
    ]
  }
}
