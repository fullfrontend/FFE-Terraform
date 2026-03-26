resource "kubernetes_namespace" "postiz" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "postiz"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
