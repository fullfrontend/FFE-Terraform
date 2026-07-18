resource "kubernetes_persistent_volume_claim" "wp_content" {
  metadata {
    name      = "wordpress-content"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
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

resource "kubernetes_persistent_volume_claim" "private_guides" {
  count = var.private_guides_storage_size != "" ? 1 : 0

  metadata {
    name      = "wordpress-private-guides"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  lifecycle {
    prevent_destroy = true
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = var.private_guides_storage_size
      }
    }
  }
}
