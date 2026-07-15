resource "kubernetes_config_map_v1" "runtime" {
  metadata {
    name      = "grangesdutilleul-runtime"
    namespace = kubernetes_namespace.stage.metadata[0].name
  }

  data = {
    "Caddyfile" = <<-EOT
      :80 {
        encode gzip

        root * /var/www/html
        php_fastcgi 127.0.0.1:9000 {
          header_up X-Forwarded-Proto https
        }
        file_server

        @disallowed {
          path /xmlrpc.php
          path *.sql
          path /wp-content/uploads/*.php
        }

        rewrite @disallowed "/index.php"
      }
    EOT

    "dev.ini" = <<-EOT
      opcache.enable=0
      opcache.enable_cli=0
    EOT
  }
}
