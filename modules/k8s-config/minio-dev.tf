locals {
  minio_s3_url = "http://minio-dev.${kubernetes_namespace.infra.metadata[0].name}.svc.cluster.local:9000"
}

resource "kubernetes_persistent_volume" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name = "minio-dev-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes = ["ReadWriteOnce"]
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      host_path {
        path = var.velero_dev_host_path
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name      = "minio-dev-pvc"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.minio_dev[0].metadata[0].name
  }
}

resource "kubernetes_secret" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name      = "minio-dev-credentials"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    accesskey = var.velero_access_key
    secretkey = var.velero_secret_key
  }
}

resource "kubernetes_deployment" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name      = "minio-dev"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "minio-dev"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "minio-dev"
      }
    }

    template {
      metadata {
        labels = {
          app = "minio-dev"
        }
      }

      spec {
        container {
          name  = "minio"
          image = "quay.io/minio/minio:RELEASE.2024-05-10T01-41-38Z"
          args  = ["server", "/data", "--console-address", ":9001"]

          env {
            name = "MINIO_ACCESS_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_dev[0].metadata[0].name
                key  = "accesskey"
              }
            }
          }
          env {
            name = "MINIO_SECRET_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.minio_dev[0].metadata[0].name
                key  = "secretkey"
              }
            }
          }

          port {
            name           = "s3"
            container_port = 9000
          }
          port {
            name           = "console"
            container_port = 9001
          }

          volume_mount {
            name       = "data"
            mount_path = "/data"
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.minio_dev[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name      = "minio-dev"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "minio-dev"
    }
  }

  spec {
    selector = {
      app = "minio-dev"
    }

    port {
      name        = "s3"
      port        = 9000
      target_port = 9000
    }

    port {
      name        = "console"
      port        = 9001
      target_port = 9001
    }
  }
}
