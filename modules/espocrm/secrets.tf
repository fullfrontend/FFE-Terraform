resource "kubernetes_secret" "db" {
  metadata {
    name      = "espocrm-db"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
  }

  data = {
    db_host     = var.db_host
    db_port     = tostring(var.db_port)
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  }
}

resource "kubernetes_secret" "admin" {
  metadata {
    name      = "espocrm-admin"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
  }

  data = {
    admin_user     = var.admin_user
    admin_password = var.admin_password
    admin_email    = var.admin_email
  }
}

resource "kubernetes_secret" "keys" {
  metadata {
    name      = "espocrm-keys"
    namespace = kubernetes_namespace.espocrm.metadata[0].name
  }

  data = {
    crypt_key       = var.crypt_key
    hash_secret_key = var.hash_secret_key
    password_salt   = var.password_salt
  }
}
