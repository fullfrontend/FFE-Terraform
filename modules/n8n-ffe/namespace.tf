resource "kubernetes_namespace" "n8n" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"    = "n8n"
      "app.kubernetes.io/part-of" = "apps"
    }
  }
}
