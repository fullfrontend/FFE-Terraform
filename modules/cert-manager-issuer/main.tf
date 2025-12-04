/*
    Issuer Let's Encrypt (prod only)
    Executed via kubectl to avoid CRD discovery issues during plan.
*/
resource "null_resource" "letsencrypt_prod" {
  count = var.is_prod ? 1 : 0

  triggers = {
    acme_email      = var.acme_email
    kubeconfig_path = var.kubeconfig_path
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -euo pipefail

      if [ -z "${var.acme_email}" ]; then
        echo "acme_email must be set for Let's Encrypt issuer" >&2
        exit 1
      fi

      kubectl --kubeconfig="${var.kubeconfig_path}" apply -f - <<'YAML'
      apiVersion: cert-manager.io/v1
      kind: Issuer
      metadata:
        name: letsencrypt-prod
        namespace: infra
      spec:
        acme:
          email: ${var.acme_email}
          server: https://acme-v02.api.letsencrypt.org/directory
          privateKeySecretRef:
            name: letsencrypt-prod
          solvers:
            - http01:
                ingress:
                  class: traefik
      YAML
    EOT
  }
}
