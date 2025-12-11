locals {
  analytics_sets = concat(
    [for idx, d in var.domains : { name = "domains[${idx}]", value = d }],
    [
      { name = "baseURL", value = "https://${var.host}" },
      { name = "secret.adminName", value = var.admin_username }
    ]
  )

  analytics_values = {
    # Persistance des données Vince sur un PVC monté à /data
    dataPath = "/data"
    volumeMounts = [
      {
        name      = "analytics-data"
        mountPath = "/data"
      }
    ]
    volumes = [
      {
        name = "analytics-data"
        persistentVolumeClaim = {
          claimName = kubernetes_persistent_volume_claim.analytics_data.metadata[0].name
        }
      }
    ]
  }
}

resource "helm_release" "vince" {
  name      = "vince"
  namespace = kubernetes_namespace.analytics.metadata[0].name

  /*
      Vince analytics helm chart with:
      - pre-seeded domains
      - admin credentials
  */
  repository      = "https://vinceanalytics.com/charts"
  chart           = "vince"
  version         = var.chart_version != "" ? var.chart_version : null
  cleanup_on_fail = true
  atomic          = true

  set = concat(
    local.analytics_sets,
    var.enable_tls ? [
      {
        name  = "ingress.annotations.cert-manager\\.io/cluster-issuer"
        value = "letsencrypt-prod"
      },
      {
        name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls"
        value = "true"
      },
      {
        name  = "ingress.annotations.kubernetes\\.io/ingress\\.allow-http"
        value = "true"
      },
      {
        name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints"
        value = "web\\,websecure"
      },
      {
        name  = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares"
        value = "infra-redirect-https@kubernetescrd"
      },
      {
        name  = "ingress.tls[0].hosts[0]"
        value = var.host
      },
      {
        name  = "ingress.tls[0].secretName"
        value = var.tls_secret_name
      }
    ] : []
  )
  values = [
    yamlencode(local.analytics_values)
  ]
  set_sensitive = [
    {
      name  = "secret.adminPassword"
      value = var.admin_password
    }
  ]
}
