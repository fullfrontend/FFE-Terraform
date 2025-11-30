resource "kubernetes_secret" "velero" {
  count = var.enable_velero ? 1 : 0

  metadata {
    name      = "velero-credentials"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    cloud = <<-EOT
      [default]
      aws_access_key_id=${var.velero_access_key}
      aws_secret_access_key=${var.velero_secret_key}
    EOT
  }
}

resource "helm_release" "velero" {
  count = var.enable_velero ? 1 : 0

  name       = "velero"
  namespace  = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://vmware-tanzu.github.io/helm-charts"
  chart           = "velero"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "configuration.provider"
      value = "aws"
    },
    {
      name  = "configuration.backupStorageLocation[0].name"
      value = "default"
    },
    {
      name  = "configuration.backupStorageLocation[0].bucket"
      value = var.velero_bucket
    },
    {
      name  = "configuration.backupStorageLocation[0].config.region"
      value = var.velero_region
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3ForcePathStyle"
      value = true
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3Url"
      value = var.velero_s3_url
    },
    {
      name  = "credentials.existingSecret"
      value = kubernetes_secret.velero[0].metadata[0].name
    },
    {
      name  = "deployNodeAgent"
      value = false
    }
  ]
}
