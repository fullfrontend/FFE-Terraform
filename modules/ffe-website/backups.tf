/*
    Velero schedule scoped to the WordPress namespace (PVC included via node-agent).
    Lives in the Velero namespace (infra).
*/
resource "kubernetes_manifest" "wordpress_backup" {
  manifest = {
    apiVersion = "velero.io/v1"
    kind       = "Schedule"
    metadata = {
      name      = "wordpress-daily"
      namespace = var.velero_namespace
      labels = {
        "app.kubernetes.io/name"       = "velero"
        "app.kubernetes.io/component"  = "backup"
        "app.kubernetes.io/part-of"    = "wordpress"
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }
    spec = {
      schedule = "30 2 * * *" # 02:30 UTC daily
      template = {
        ttl                = "720h"
        includedNamespaces = [var.namespace]
      }
    }
  }
}
