resource "kubernetes_namespace" "wordpress" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "wordpress"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}

resource "kubernetes_secret" "db" {
  metadata {
    name      = "wordpress-db"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    db_host     = var.db_host
    db_port     = tostring(var.db_port)
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  }
}

resource "kubernetes_config_map" "apache_servername" {
  metadata {
    name      = "wordpress-apache-servername"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    "servername.conf" = "ServerName ${var.host}"
  }
}

resource "kubernetes_secret" "dockerhub" {
  count = var.dockerhub_user != "" ? 1 : 0

  metadata {
    name      = "dockerhub-credentials"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.dockerhub_user
          password = var.dockerhub_pat
          email    = var.dockerhub_email
          auth     = base64encode("${var.dockerhub_user}:${var.dockerhub_pat}")
        }
      }
    })
  }
}

resource "kubernetes_persistent_volume_claim" "wp_content" {
  metadata {
    name      = "wordpress-content"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.storage_size
      }
    }
  }
}

resource "kubernetes_deployment" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    labels = {
      app = "wordpress"
    }
  }

  /*
      Vanilla WordPress deployment:
      - external MariaDB
      - PVC for wp-content
  */
  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = "wordpress"
      }
    }

    template {
      metadata {
        labels = {
          app = "wordpress"
        }
      }

      spec {
        container {
          name  = "wordpress"
          image = var.image

          port {
            name           = "http"
            container_port = 80
          }

          env {
            name = "WORDPRESS_DB_HOST"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_host"
              }
            }
          }
          env {
            name = "WORDPRESS_DB_PORT"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_port"
              }
            }
          }
          env {
            name = "WORDPRESS_DB_NAME"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_name"
              }
            }
          }
          env {
            name = "WORDPRESS_DB_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_user"
              }
            }
          }
          env {
            name = "WORDPRESS_DB_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.db.metadata[0].name
                key  = "db_password"
              }
            }
          }

          volume_mount {
            name       = "wordpress-content"
            mount_path = "/var/www/html"
          }

          volume_mount {
            name       = "apache-servername"
            mount_path = "/etc/apache2/conf-enabled/servername.conf"
            sub_path   = "servername.conf"
            read_only  = true
          }
        }

        volume {
          name = "wordpress-content"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.wp_content.metadata[0].name
          }
        }

        volume {
          name = "apache-servername"

          config_map {
            name = kubernetes_config_map.apache_servername.metadata[0].name
          }
        }

        dynamic "image_pull_secrets" {
          for_each = var.dockerhub_user != "" ? [1] : []
          content {
            name = kubernetes_secret.dockerhub[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    labels = {
      app = "wordpress"
    }
  }

  spec {
    selector = {
      app = "wordpress"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_ingress_v1" "wordpress" {
  metadata {
    name      = "wordpress"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    annotations = var.enable_tls ? {
      "kubernetes.io/ingress.class"              = var.ingress_class_name
      "cert-manager.io/cluster-issuer"           = "letsencrypt-prod"
      "traefik.ingress.kubernetes.io/router.tls" = "true"
      } : {
      "kubernetes.io/ingress.class" = var.ingress_class_name
    }
  }

  spec {
    ingress_class_name = var.ingress_class_name

    rule {
      host = var.host
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.wordpress.metadata[0].name
              port {
                number = 80
              }
            }
          }
        }
      }
    }

    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.host]
        secret_name = var.tls_secret_name
      }
    }
  }
}
