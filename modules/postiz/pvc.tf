resource "kubernetes_persistent_volume_claim" "uploads" {
  metadata {
    name      = "postiz-uploads"
    namespace = kubernetes_namespace.postiz.metadata[0].name
    labels = {
      app = "postiz"
    }
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.storage_size
      }
    }

    storage_class_name = var.storage_class_name != "" ? var.storage_class_name : null
  }
}
