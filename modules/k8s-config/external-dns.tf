resource "helm_release" "external_dns" {
  name       = "external-dns"
  namespace  = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://kubernetes-sigs.github.io/external-dns/"
  chart           = "external-dns"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "provider"
      value = "digitalocean"
    },
    {
      name  = "policy"
      value = "sync"
    },
    {
      name  = "sources[0]"
      value = "ingress"
    },
    {
      name  = "txtOwnerId"
      value = var.cluster_name
    }
  ]

  set_sensitive = [
    {
      name  = "digitalOcean.apiToken"
      value = var.do_token
    }
  ]
}
