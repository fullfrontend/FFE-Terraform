resource "helm_release" "traefik" {
  name       = "traefik"
  namespace  = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://traefik.github.io/charts"
  chart           = "traefik"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "deployment.replicas"
      value = 2
    },
    {
      name  = "service.type"
      value = "LoadBalancer"
    },
    {
      name  = "service.spec.loadBalancerClass"
      value = ""
    },
    {
      name  = "service.annotations.service\\.beta\\.kubernetes\\.io/do-loadbalancer-name"
      value = format("%s-traefik", var.cluster_name)
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
  ]
}
