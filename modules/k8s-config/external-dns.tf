/*
    external-dns only in prod:
    sync ingress hosts to DigitalOcean DNS
*/
resource "kubernetes_secret" "external_dns_do_token" {
  count = var.is_prod ? 1 : 0

  metadata {
    name      = "external-dns-do-token"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    DO_TOKEN = var.do_token
  }
}

locals {
  external_dns_sets = concat(
    [
      { name = "provider", value = "digitalocean" },
      { name = "registry", value = "txt" },
      { name = "policy", value = "sync" },
      { name = "interval", value = "1m" },
      { name = "sources[0]", value = "service" },
      { name = "sources[1]", value = "ingress" },
      { name = "txtOwnerId", value = var.cluster_name },
      { name = "txtPrefix", value = "_extdns." },
      { name = "env[0].name", value = "DO_TOKEN" },
      { name = "env[0].valueFrom.secretKeyRef.name", value = kubernetes_secret.external_dns_do_token[0].metadata[0].name },
      { name = "env[0].valueFrom.secretKeyRef.key", value = "DO_TOKEN" }
    ],
    [for idx, d in concat([var.root_domain], var.extra_domain_filters) : { name = "domainFilters[${idx}]", value = d }]
  )
}

resource "helm_release" "external_dns" {
  count     = var.is_prod ? 1 : 0
  name      = "external-dns"
  namespace = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://kubernetes-sigs.github.io/external-dns/"
  chart           = "external-dns"
  cleanup_on_fail = true
  atomic          = true

  set = local.external_dns_sets

  set_sensitive = [
    {
      name  = "digitalOcean.apiToken"
      value = var.do_token
    }
  ]
}
