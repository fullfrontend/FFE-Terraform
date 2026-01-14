/*
    Secrets regroupés pour k8s-config (external-dns, Velero, Postgres/MariaDB, MinIO dev).
*/

resource "kubernetes_secret" "external_dns_ovh" {
  count = var.is_prod ? 1 : 0

  metadata {
    name      = "external-dns-ovh"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    OVH_ENDPOINT           = var.ovh_endpoint
    OVH_APPLICATION_KEY    = var.ovh_application_key
    OVH_APPLICATION_SECRET = var.ovh_application_secret
    OVH_CONSUMER_KEY       = var.ovh_consumer_key
  }
}

resource "kubernetes_secret" "velero" {
  count = var.enable_velero ? 1 : 0

  metadata {
    name      = "velero-credentials"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    cloud = <<-EOT
      [default]
      aws_access_key_id=${var.is_prod ? var.velero_access_key : var.minio_access_key}
      aws_secret_access_key=${var.is_prod ? var.velero_secret_key : var.minio_secret_key}
    EOT
  }
}

resource "kubernetes_secret" "minio_dev" {
  count = var.is_prod || !var.enable_velero ? 0 : 1

  metadata {
    name      = "minio-dev-credentials"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    accesskey = var.minio_access_key
    secretkey = var.minio_secret_key
  }
}

resource "kubernetes_secret" "postgres" {
  metadata {
    name      = "postgres-root"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    POSTGRES_PASSWORD = var.postgres_root_password
  }
}

resource "kubernetes_secret" "postgres_init" {
  count = length(var.postgres_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "postgres-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = local.postgres_init_creds
}

resource "kubernetes_secret" "postgres_apps" {
  count = length(var.postgres_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "postgres-apps"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = merge(
    { POSTGRES_HOST = kubernetes_service.postgres.metadata[0].name },
    length(var.postgres_app_credentials) > 0 ? local.postgres_init_creds : {}
  )
}

resource "kubernetes_secret" "mariadb" {
  metadata {
    name      = "mariadb-root"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = {
    MARIADB_ROOT_PASSWORD = var.mariadb_root_password
  }
}

resource "kubernetes_secret" "mariadb_init" {
  count = length(var.mariadb_app_credentials) > 0 ? 1 : 0

  metadata {
    name      = "mariadb-initdb"
    namespace = kubernetes_namespace.data.metadata[0].name
  }

  data = local.mariadb_init_creds
}

/*
    App-facing secrets: consumed by apps (host/port/db/user/password).
    Init secrets live in data namespace (mariadb-initdb) and are admin-only.
*/
resource "kubernetes_secret" "mariadb_apps" {
  for_each = { for app in var.mariadb_app_credentials : app.name => app }

  metadata {
    name      = "mariadb-${each.value.name}"
    namespace = kubernetes_namespace.data.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "db"                           = "mariadb"
      "app"                          = each.value.name
    }
  }

  data = {
    host     = kubernetes_service.mariadb.metadata[0].name
    port     = "3306"
    database = each.value.db_name
    user     = each.value.user
    password = each.value.password
  }
}
