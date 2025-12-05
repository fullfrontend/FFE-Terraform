resource "kubernetes_persistent_volume" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  /*
      HostPath PV for MinIO dev data
      Stored under ./data/<cluster_name> (git-ignored)
  */
  metadata {
    name = "minio-dev-pv"
  }

  spec {
    capacity = {
      storage = "10Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = "standard"
    persistent_volume_reclaim_policy = "Retain"
    persistent_volume_source {
      host_path {
        path = abspath("${path.root}/data/${var.cluster_name}")
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

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard"
    resources {
      requests = {
        storage = "10Gi"
      }
    }
    volume_name = kubernetes_persistent_volume.minio_dev[0].metadata[0].name
  }
}
