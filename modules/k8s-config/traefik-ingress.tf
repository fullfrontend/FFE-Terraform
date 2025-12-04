/*
    Traefik ingress controller via Helm
    - LoadBalancer in prod
    - NodePort in dev
*/
locals {
  traefik_service_type = var.is_prod ? "LoadBalancer" : "NodePort"
  traefik_sets_prod = [
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-name"
      value = format("%s-traefik", var.cluster_name)
    }
  ]
}

resource "helm_release" "traefik" {
  count     = var.is_prod ? 1 : 0
  name      = "traefik"
  namespace = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://traefik.github.io/charts"
  chart           = "traefik"
  cleanup_on_fail = true
  atomic          = true

  set = concat([
    {
      name  = "deployment.replicas"
      value = 2
    },
    {
      name  = "service.type"
      value = local.traefik_service_type
    },
    {
      name  = "ingressClass.enabled"
      value = true
    },
    {
      name  = "ingressClass.isDefaultClass"
      value = true
    },
    {
      name  = "ports.websecure.tls.enabled"
      value = true
    }
  ], var.is_prod ? local.traefik_sets_prod : [])
}
