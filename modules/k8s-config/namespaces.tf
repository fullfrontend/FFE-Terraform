/*
    Core namespaces:
    - infra (ingress/ops)
    - data (databases)
    - metrics (monitoring/alerts)
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

resource "kubernetes_namespace" "metrics" {
  metadata {
    name = "metrics"
  }
}
