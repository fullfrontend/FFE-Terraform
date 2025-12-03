/*
    Core namespaces:
    - infra (ingress/ops)
    - data (databases)
*/
resource "kubernetes_namespace" "infra" {
  metadata {
    name = "infra"
  }
}

resource "kubernetes_namespace" "data" {
  metadata {
    name = "data"
  }
}
