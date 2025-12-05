resource "kubernetes_namespace" "mailu" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "mailu"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
