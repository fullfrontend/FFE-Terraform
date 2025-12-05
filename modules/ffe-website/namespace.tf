resource "kubernetes_namespace" "wordpress" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "wordpress"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
