resource "kubernetes_config_map" "apache_servername" {
  metadata {
    name      = "wordpress-apache-servername"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    "servername.conf" = "ServerName ${var.host}"
  }
}

resource "kubernetes_config_map" "php_uploads" {
  metadata {
    name      = "wordpress-php-uploads"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    "uploads.ini" = <<-EOT
      upload_max_filesize = 100M
      post_max_size = 100M
    EOT
  }
}
