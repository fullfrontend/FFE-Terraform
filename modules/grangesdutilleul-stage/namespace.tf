resource "kubernetes_namespace" "stage" {
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/name"        = "grangesdutilleul"
      "app.kubernetes.io/component"   = "wordpress"
      "app.kubernetes.io/environment" = "development"
      "app.kubernetes.io/part-of"     = "client-staging"
    }
  }
}
