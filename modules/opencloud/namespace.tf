resource "kubernetes_namespace" "opencloud" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "opencloud"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
