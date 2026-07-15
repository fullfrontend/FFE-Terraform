resource "kubernetes_persistent_volume_claim_v1" "uploads" {
  metadata {
    name      = "grangesdutilleul-uploads"
    namespace = kubernetes_namespace.stage.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.uploads_storage_size
      }
    }
  }
}
