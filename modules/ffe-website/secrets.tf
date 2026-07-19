resource "kubernetes_secret" "db" {
  metadata {
    name      = "wordpress-db"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    db_host     = var.db_host
    db_port     = tostring(var.db_port)
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
  }
}

resource "kubernetes_secret" "smtp" {
  metadata {
    name      = "wordpress-smtp"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    smtp_password = var.smtp_pass
  }
}

resource "random_password" "guide_context_key" {
  count = var.private_guides_storage_size != "" ? 1 : 0

  length  = 64
  special = false
}

resource "random_password" "guide_encryption_key" {
  count = var.private_guides_storage_size != "" ? 1 : 0

  length  = 64
  special = false
}

resource "kubernetes_secret" "guide_delivery" {
  count = var.private_guides_storage_size != "" ? 1 : 0

  metadata {
    name      = "wordpress-guide-delivery"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  data = {
    context_key    = random_password.guide_context_key[0].result
    encryption_key = random_password.guide_encryption_key[0].result
  }
}

resource "kubernetes_secret" "dockerhub" {
  count = var.dockerhub_user != "" ? 1 : 0

  metadata {
    name      = "dockerhub-credentials"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "https://index.docker.io/v1/" = {
          username = var.dockerhub_user
          password = var.dockerhub_pat
          email    = var.dockerhub_email
          auth     = base64encode("${var.dockerhub_user}:${var.dockerhub_pat}")
        }
      }
    })
  }
}
