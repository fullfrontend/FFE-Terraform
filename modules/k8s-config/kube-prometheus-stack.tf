/*
    Monitoring stack (Prometheus Operator, Grafana, alerting)
    Deployed only when enabled (default true) and on prod
*/
resource "helm_release" "kube_prometheus_stack" {
  count            = var.is_prod && var.enable_kube_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.metrics.metadata[0].name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  cleanup_on_fail  = true
  atomic           = true
  create_namespace = false

  set = [
    {
      name  = "namespaceOverride"
      value = kubernetes_namespace.metrics.metadata[0].name
    },
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "grafana.enabled"
      value = "false"
    },
    {
      name  = "alertmanager.enabled"
      value = "false"
    }
  ]
}
