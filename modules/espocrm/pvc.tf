resource "kubernetes_persistent_volume_claim" "espocrm_data" {
  metadata {
    name      = "espocrm-data"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
    labels = {
      app = "espocrm"
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
