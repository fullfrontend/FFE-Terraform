/*
    Velero backups:
    - Spaces in prod
    - MinIO in dev
    Credentials injected via secret
*/
resource "helm_release" "velero" {
  count = var.enable_velero ? 1 : 0

  name      = "velero"
  namespace = kubernetes_namespace.infra.metadata[0].name

  repository      = "https://vmware-tanzu.github.io/helm-charts"
  chart           = "velero"
  cleanup_on_fail = true
  atomic          = true

  set = [
    {
      name  = "configuration.backupStorageLocation[0].name"
      value = "default"
    },
    {
      name  = "configuration.backupStorageLocation[0].provider"
      value = "aws"
    },
    {
      name  = "configuration.backupStorageLocation[0].bucket"
      value = var.is_prod ? var.velero_bucket : var.cluster_name
    },
    {
      name  = "configuration.backupStorageLocation[0].config.region"
      value = var.is_prod ? var.region : "dev-local"
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3ForcePathStyle"
      value = true
    },
    {
      name  = "configuration.backupStorageLocation[0].config.s3Url"
      value = var.is_prod ? var.velero_s3_url : local.minio_s3_url
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].name"
      value = "default"
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].provider"
      value = "aws"
    },
    {
      name  = "configuration.volumeSnapshotLocation[0].config.region"
      value = var.is_prod ? var.region : "dev-local"
    },
    {
      name  = "deployNodeAgent"
      value = true
    },
    {
      name  = "configuration.defaultVolumesToFsBackup"
      value = true
    },
    {
      name  = "credentials.existingSecret"
      value = kubernetes_secret.velero[0].metadata[0].name
    },
    {
      name  = "upgradeCRDs"
      value = false
    },
    {
      name  = "schedules.db.schedule"
      value = "0 3 * * *"
    },
    {
      name  = "schedules.db.template.ttl"
      value = "720h"
    },
    {
      name  = "schedules.db.template.includedNamespaces[0]"
      value = "data"
    },
    {
      name  = "kubectl.image.repository"
      value = "registry.k8s.io/kubectl"
    },
    {
      name  = "kubectl.image.tag"
      value = "latest" # 1.34 inexistant; pin to a stable kubectl tag
    },
    {
      name  = "initContainers[0].name"
      value = "velero-plugin-for-aws"
    },
    {
      name  = "initContainers[0].image"
      value = "velero/velero-plugin-for-aws:v1.9.2"
    },
    {
      name  = "initContainers[0].volumeMounts[0].mountPath"
      value = "/target"
    },
    {
      name  = "initContainers[0].volumeMounts[0].name"
      value = "plugins"
    }
  ]

}
