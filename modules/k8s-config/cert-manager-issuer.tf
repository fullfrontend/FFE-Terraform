/*
    Issuer ACME Let's Encrypt (namespace infra)
    - activé uniquement en prod si acme_email est renseigné
*/
resource "kubernetes_manifest" "letsencrypt_prod_issuer" {
  count      = var.is_prod && var.acme_email != "" ? 1 : 0
  depends_on = [
    helm_release.cert_manager,
    kubernetes_namespace.infra
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Issuer"
    metadata = {
      name      = "letsencrypt-prod"
      namespace = kubernetes_namespace.infra.metadata[0].name
    }
    spec = {
      acme = {
        email  = var.acme_email
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-prod"
        }
        solvers = [
          {
            http01 = {
              ingress = {
                class = "traefik"
              }
            }
          }
        ]
      }
    }
  }
}
