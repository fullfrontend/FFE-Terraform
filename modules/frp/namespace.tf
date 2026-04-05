resource "kubernetes_namespace" "frp" {
  metadata {
    name = var.namespace
    labels = {
      app = "frp"
    }
  }
}
