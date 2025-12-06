locals {
  grafana_secret_name = var.is_prod && var.enable_kube_prometheus_stack ? kubernetes_secret.grafana_admin[0].metadata[0].name : ""
}

resource "helm_release" "kube_prometheus_stack" {
  count            = var.is_prod && var.enable_kube_prometheus_stack ? 1 : 0
  name             = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.monitoring.metadata[0].name
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  cleanup_on_fail  = true
  atomic           = true
  create_namespace = false

  set = [
    {
      name  = "namespaceOverride"
      value = kubernetes_namespace.monitoring.metadata[0].name
    },
    {
      name  = "crds.enabled"
      value = "true"
    },
    {
      name  = "grafana.enabled"
      value = "true"
    },
    {
      name  = "alertmanager.enabled"
      value = "false"
    },
    /*
        Persist Prometheus data (otherwise emptyDir is used and data is lost on restart).
        You can adjust storageClass if needed; default will use the cluster default SC.
    */
    {
      name  = "prometheus.prometheusSpec.retention"
      value = "15d"
    },
    {
      name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
      value = "5Gi"
    },
    /*
        Grafana ingress: tls + HTTP->HTTPS redirect (Traefik middleware infra-redirect-https).
        Annotations quoted as strings.
    */
    {
      name  = "grafana.ingress.enabled"
      value = "true"
    },
    {
      name  = "grafana.ingress.ingressClassName"
      value = "traefik"
    },
    {
      name  = "grafana.ingress.hosts[0]"
      value = var.grafana_host
    },
    {
      name  = "grafana.ingress.tls[0].hosts[0]"
      value = var.grafana_host
    },
    {
      name  = "grafana.ingress.tls[0].secretName"
      value = "grafana-tls"
    },
    {
      name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.class"
      value = "traefik"
    },
    {
      name  = "grafana.ingress.annotations.kubernetes\\.io/ingress\\.allow-http"
      value = "'true'"
    },
    {
      name  = "grafana.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
      value = "web\\,websecure"
    },
    {
      name  = "grafana.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares"
      value = "infra-redirect-https@kubernetescrd"
    },
    {
      name  = "grafana.ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls"
      value = "'true'"
    },
    {
      name  = "grafana.ingress.annotations.cert-manager\\.io/cluster-issuer"
      value = "letsencrypt-prod"
    },
    /*
        Admin credentials provided via existing secret
    */
    {
      name  = "grafana.admin.existingSecret"
      value = local.grafana_secret_name
    }
  ]
}
