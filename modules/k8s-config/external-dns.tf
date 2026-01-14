/*
    external-dns only in prod:
    sync ingress hosts to OVH DNS
*/
locals {
  external_dns_sets = concat(
    [
      { name = "provider", value = "ovh" },
      { name = "registry", value = "txt" },
      { name = "policy", value = "sync" },
      { name = "interval", value = "1m" },
      { name = "sources[0]", value = "service" },
      { name = "sources[1]", value = "ingress" },
      { name = "txtOwnerId", value = var.cluster_name },
      { name = "txtPrefix", value = "_extdns." },
      { name = "env[0].name", value = "OVH_ENDPOINT" },
      { name = "env[0].valueFrom.secretKeyRef.name", value = kubernetes_secret.external_dns_ovh[0].metadata[0].name },
      { name = "env[0].valueFrom.secretKeyRef.key", value = "OVH_ENDPOINT" },
      { name = "env[1].name", value = "OVH_APPLICATION_KEY" },
      { name = "env[1].valueFrom.secretKeyRef.name", value = kubernetes_secret.external_dns_ovh[0].metadata[0].name },
      { name = "env[1].valueFrom.secretKeyRef.key", value = "OVH_APPLICATION_KEY" },
      { name = "env[2].name", value = "OVH_APPLICATION_SECRET" },
      { name = "env[2].valueFrom.secretKeyRef.name", value = kubernetes_secret.external_dns_ovh[0].metadata[0].name },
      { name = "env[2].valueFrom.secretKeyRef.key", value = "OVH_APPLICATION_SECRET" },
      { name = "env[3].name", value = "OVH_CONSUMER_KEY" },
      { name = "env[3].valueFrom.secretKeyRef.name", value = kubernetes_secret.external_dns_ovh[0].metadata[0].name },
      { name = "env[3].valueFrom.secretKeyRef.key", value = "OVH_CONSUMER_KEY" }
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
}
