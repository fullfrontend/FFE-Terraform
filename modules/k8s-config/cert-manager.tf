resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://charts.jetstack.io"
  chart           = "cert-manager"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "installCRDs"
      value = true
    }
  ]
}
