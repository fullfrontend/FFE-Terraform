/*
    Shared Traefik middleware to force HTTPS (used by ingresses via annotation)
*/
resource "kubernetes_manifest" "redirect_https" {
  count      = var.is_prod ? 1 : 0
  depends_on = [helm_release.traefik]

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "redirect-https"
      namespace = kubernetes_namespace.infra.metadata[0].name
    }
    spec = {
      redirectScheme = {
        scheme    = "https"
        port      = "443"
        permanent = true
      }
    }
  }
}
