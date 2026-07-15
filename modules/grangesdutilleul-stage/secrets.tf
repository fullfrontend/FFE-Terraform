resource "kubernetes_secret_v1" "database" {
  metadata {
    name      = "grangesdutilleul-database"
    namespace = kubernetes_namespace.stage.metadata[0].name
  }

  data = {
    WORDPRESS_DB_HOST     = "${var.db_host}:${var.db_port}"
    WORDPRESS_DB_NAME     = var.db_name
    WORDPRESS_DB_USER     = var.db_user
    WORDPRESS_DB_PASSWORD = var.db_password
  }
}

resource "kubernetes_secret_v1" "dockerhub" {
  count = var.dockerhub_user != "" ? 1 : 0

  metadata {
    name      = "dockerhub-credentials"
    namespace = kubernetes_namespace.stage.metadata[0].name
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
