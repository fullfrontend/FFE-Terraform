resource "kubernetes_namespace" "registry" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "registry"
      "app.kubernetes.io/part-of" = "infra"
    }
  }
}

resource "kubernetes_secret" "htpasswd" {
  count = var.htpasswd_entry != "" ? 1 : 0

  metadata {
    name      = "registry-htpasswd"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  data = {
    htpasswd = var.htpasswd_entry
  }
}

resource "kubernetes_config_map" "config" {
  metadata {
    name      = "registry-config"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  data = {
    "config.json" = jsonencode({
      storage = {
        rootDirectory = "/var/lib/registry"
      }
      http = {
        address = "0.0.0.0"
        port    = "5000"
      }
      log = {
        level = "info"
      }
      auth = var.htpasswd_entry != "" ? {
        htpasswd = {
          path = "/etc/zot/htpasswd"
        }
      } : null
    })
  }
}

resource "kubernetes_persistent_volume_claim" "data" {
  metadata {
    name      = "registry-data"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = null
  }
}

resource "kubernetes_deployment" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "registry"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "registry"
      }
    }

    template {
      metadata {
        labels = {
          app = "registry"
        }
      }

      spec {
        container {
          name  = "zot"
          image = "ghcr.io/project-zot/zot-linux-amd64:latest"

          args = [
            "/etc/zot/config.json",
          ]

          port {
            name           = "http"
            container_port = 5000
          }

          volume_mount {
            name       = "config"
            mount_path = "/etc/zot"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/lib/registry"
          }

          dynamic "volume_mount" {
            for_each = var.htpasswd_entry != "" ? [1] : []
            content {
              name       = "htpasswd"
              mount_path = "/etc/zot/htpasswd"
              sub_path   = "htpasswd"
              read_only  = true
            }
          }
        }

        volume {
          name = "config"

          config_map {
            name = kubernetes_config_map.config.metadata[0].name
          }
        }

        volume {
          name = "data"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.data.metadata[0].name
          }
        }

        dynamic "volume" {
          for_each = var.htpasswd_entry != "" ? [1] : []
          content {
            name = "htpasswd"

            secret {
              secret_name = kubernetes_secret.htpasswd[0].metadata[0].name
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
    labels = {
      app = "registry"
    }
  }

  spec {
    port {
      name        = "http"
      port        = 5000
      target_port = 5000
    }

    selector = {
      app = "registry"
    }
  }
}

resource "kubernetes_ingress_v1" "registry" {
  metadata {
    name      = "registry"
    namespace = kubernetes_namespace.registry.metadata[0].name
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
              name = kubernetes_service.registry.metadata[0].name
              port {
                number = 5000
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.host]
      secret_name = var.tls_secret_name
    }
  }
}
