resource "digitalocean_spaces_bucket" "website-public" {
  name = "website-public"
  region = var.do_region
}

resource "digitalocean_spaces_bucket" "website-backup" {
  name = "website-backup"
  region = var.do_region
  acl = "private"
}

resource "digitalocean_spaces_bucket" "mautic-public" {
  name = "mautic-public"
  region = var.do_region
}

resource "digitalocean_spaces_bucket" "mautic-backup" {
  name = "mautic-backup"
  region = var.do_region
  acl = "private"
}


resource "digitalocean_spaces_bucket_cors_configuration" "website-public" {
  bucket = digitalocean_spaces_bucket.website-public.id
  region = var.do_region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://fullfrontend.be"]
    expose_headers  = ["ETag"]
    max_age_seconds = 0
  }
}


resource "digitalocean_spaces_bucket_cors_configuration" "mautic-public" {
  bucket = digitalocean_spaces_bucket.website-public.id
  region = var.do_region

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://fullfrontend.be"]
    expose_headers  = ["ETag"]
    max_age_seconds = 0
  }
}
