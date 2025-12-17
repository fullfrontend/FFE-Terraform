resource "kubernetes_namespace" "espocrm" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "espocrm"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
