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

resource "kubernetes_config_map" "apache_webp_htaccess" {
  metadata {
    name      = "wordpress-apache-webp"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    "webp.conf" = <<-EOT
      <Directory /var/www/html>
        <IfModule mod_rewrite.c>
          RewriteEngine On
          RewriteCond %%{HTTP_ACCEPT} image/webp
          RewriteCond %%{REQUEST_FILENAME} (.*)\.(jpe?g|png|gif)$
          RewriteCond %%{REQUEST_FILENAME}\\.webp -f
          RewriteCond %%{QUERY_STRING} !type=original
          RewriteRule (.+)\\.(jpe?g|png|gif)$ %%{REQUEST_URI}.webp [T=image/webp,L]
        </IfModule>
        <IfModule mod_headers.c>
          <FilesMatch "\\.(jpe?g|png|gif)$">
            Header append Vary Accept
          </FilesMatch>
        </IfModule>
        AddType image/webp .webp
      </Directory>
    EOT
  }
}
