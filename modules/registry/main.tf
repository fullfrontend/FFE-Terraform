locals {
  use_s3                = var.storage_backend == "s3"
  s3_endpoint_effective = var.s3_endpoint != "" ? var.s3_endpoint : (var.s3_region != "" ? format("https://%s.digitaloceanspaces.com", var.s3_region) : "")
  storage_block = local.use_s3 ? {
    rootDirectory = "/var/lib/registry"
    driver        = "s3"
    s3 = {
      bucket    = var.s3_bucket
      region    = var.s3_region
      endpoint  = local.s3_endpoint_effective
      accessKey = var.s3_access_key
      secretKey = var.s3_secret_key
      secure    = var.s3_secure
    }
  } : {
    rootDirectory = "/var/lib/registry"
    driver        = "local"
    s3            = null
  }
  registry_auth_enabled = var.htpasswd_entry != ""
}

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

resource "kubernetes_secret" "config" {
  metadata {
    name      = "registry-config"
    namespace = kubernetes_namespace.registry.metadata[0].name
  }

  data = {
    "config.json" = jsonencode({
      storage = local.storage_block
      http = {
        address = "0.0.0.0"
        port    = "5000"
      }
      log = {
        level = "info"
      }
      auth = local.registry_auth_enabled ? {
        htpasswd = {
          path = "/etc/zot-auth/htpasswd"
        }
      } : null
    })
  }
}

resource "kubernetes_persistent_volume_claim" "data" {
  count = local.use_s3 ? 0 : 1

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
  lifecycle {
    precondition {
      condition = !(local.use_s3 && (var.s3_bucket == "" || local.s3_endpoint_effective == "" || var.s3_access_key == "" || var.s3_secret_key == ""))
      error_message = "S3 backend requires s3_endpoint/region (or endpoint override), s3_bucket, s3_access_key, s3_secret_key."
    }
  }

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

          dynamic "volume_mount" {
            for_each = local.use_s3 ? [] : [1]
            content {
              name       = "data"
              mount_path = "/var/lib/registry"
            }
          }

          dynamic "volume_mount" {
            for_each = var.htpasswd_entry != "" ? [1] : []
            content {
              name       = "htpasswd"
              mount_path = "/etc/zot-auth"
              read_only  = true
            }
          }
        }

        volume {
          name = "config"

          secret {
            secret_name = kubernetes_secret.config.metadata[0].name
          }
        }

        dynamic "volume" {
          for_each = local.use_s3 ? [] : [1]
          content {
            name = "data"

            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.data[0].metadata[0].name
            }
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
