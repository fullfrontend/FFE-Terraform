locals {
  postiz_scheme               = var.enable_tls ? "https" : "http"
  postiz_base_url             = format("%s://%s", local.postiz_scheme, var.host)
  postiz_backend_public_url   = format("%s/api", local.postiz_base_url)
  postiz_backend_internal_url = "http://localhost:5000/api"
  postiz_db_url               = format("postgresql://%s:%s@%s:%d/%s", var.db_user, urlencode(var.db_password), var.db_host, var.db_port, var.db_name)
  postiz_redis_service_name   = "postiz-redis-master"
  postiz_redis_url            = format("redis://:%s@%s:6379", urlencode(var.redis_password), local.postiz_redis_service_name)
}

resource "helm_release" "redis" {
  name       = "postiz-redis"
  namespace  = kubernetes_namespace.postiz.metadata[0].name
  repository = "https://charts.redis.io/"
  chart      = "redis"

  cleanup_on_fail = true
  atomic          = true

  set = [
    { name = "architecture", value = "standalone" },
    { name = "auth.enabled", value = true },
    { name = "master.persistence.enabled", value = true },
    { name = "master.persistence.size", value = var.redis_storage_size },
  ]

  set_sensitive = [
    { name = "auth.password", value = var.redis_password },
  ]
}

resource "helm_release" "postiz" {
  lifecycle {
    precondition {
      condition     = var.db_host != "" && var.db_name != "" && var.db_user != "" && var.db_password != "" && var.jwt_secret != "" && var.redis_password != ""
      error_message = "Postiz requires db_host, db_name, db_user, db_password, jwt_secret and redis_password."
    }
  }

  name       = "postiz"
  namespace  = kubernetes_namespace.postiz.metadata[0].name
  repository = "oci://ghcr.io/gitroomhq/postiz-helmchart/charts"
  chart      = "postiz-app"
  version    = var.chart_version != "" ? var.chart_version : null
  depends_on = [helm_release.redis]

  cleanup_on_fail = true
  atomic          = true
  force_update    = true

  set = concat([
    { name = "postgresql.enabled", value = false },
    { name = "redis.enabled", value = false },

    { name = "env.FRONTEND_URL", value = local.postiz_base_url },
    { name = "env.NEXT_PUBLIC_BACKEND_URL", value = local.postiz_backend_public_url },
    { name = "env.BACKEND_INTERNAL_URL", value = local.postiz_backend_internal_url },
    { name = "env.MAIN_URL", value = local.postiz_base_url },
    { name = "env.STORAGE_PROVIDER", value = var.storage_provider },
    { name = "env.UPLOAD_DIRECTORY", value = "/uploads" },
    { name = "env.NEXT_PUBLIC_UPLOAD_STATIC_DIRECTORY", value = "/uploads" },
    { name = "env.NX_ADD_PLUGINS", value = "false" },
    { name = "env.IS_GENERAL", value = "true" },
    { name = "env.DISABLE_REGISTRATION", value = tostring(var.disable_registration) },

    { name = "env.EMAIL_PROVIDER", value = var.email_provider },
    { name = "env.EMAIL_FROM_NAME", value = var.email_from_name },
    { name = "env.EMAIL_FROM_ADDRESS", value = var.email_from_address },
    { name = "env.EMAIL_HOST", value = var.email_host },
    { name = "env.EMAIL_PORT", value = var.email_port },
    { name = "env.EMAIL_SECURE", value = var.email_secure },
    { name = "env.EMAIL_USER", value = var.email_user },

    { name = "ingress.enabled", value = true },
    { name = "ingress.className", value = var.ingress_class_name },
    { name = "ingress.hosts[0].host", value = var.host },
    { name = "ingress.hosts[0].paths[0].path", value = "/" },
    { name = "ingress.hosts[0].paths[0].pathType", value = "Prefix" },
    { name = "ingress.hosts[0].paths[0].port", value = 80 },
    { name = "ingress.annotations.kubernetes\\.io/ingress\\.allow-http", value = "true" },

    { name = "extraVolumes[0].name", value = "uploads-volume" },
    { name = "extraVolumes[0].persistentVolumeClaim.claimName", value = kubernetes_persistent_volume_claim.uploads.metadata[0].name },
    { name = "extraVolumeMounts[0].name", value = "uploads-volume" },
    { name = "extraVolumeMounts[0].mountPath", value = "/uploads" },
    ], var.enable_tls ? [
    { name = "ingress.annotations.cert-manager\\.io/cluster-issuer", value = "letsencrypt-prod" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.entrypoints", value = "web,websecure" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.tls", value = "true" },
    { name = "ingress.annotations.traefik\\.ingress\\.kubernetes\\.io/router\\.middlewares", value = "infra-redirect-https@kubernetescrd" },
    { name = "ingress.tls[0].secretName", value = var.tls_secret_name },
    { name = "ingress.tls[0].hosts[0]", value = var.host },
  ] : [])

  set_sensitive = [
    { name = "secrets.DATABASE_URL", value = local.postiz_db_url },
    { name = "secrets.REDIS_URL", value = local.postiz_redis_url },
    { name = "secrets.JWT_SECRET", value = var.jwt_secret },
    { name = "secrets.RESEND_API_KEY", value = var.resend_api_key },
    { name = "secrets.CLOUDFLARE_ACCOUNT_ID", value = var.cloudflare_account_id },
    { name = "secrets.CLOUDFLARE_ACCESS_KEY", value = var.cloudflare_access_key },
    { name = "secrets.CLOUDFLARE_SECRET_ACCESS_KEY", value = var.cloudflare_secret_access_key },
    { name = "secrets.CLOUDFLARE_BUCKETNAME", value = var.cloudflare_bucketname },
    { name = "secrets.CLOUDFLARE_BUCKET_URL", value = var.cloudflare_bucket_url },
    { name = "secrets.X_API_KEY", value = var.x_api_key },
    { name = "secrets.X_API_SECRET", value = var.x_api_secret },
    { name = "secrets.LINKEDIN_CLIENT_ID", value = var.linkedin_client_id },
    { name = "secrets.LINKEDIN_CLIENT_SECRET", value = var.linkedin_client_secret },
    { name = "secrets.FACEBOOK_APP_ID", value = var.facebook_app_id },
    { name = "secrets.FACEBOOK_APP_SECRET", value = var.facebook_app_secret },
    { name = "secrets.YOUTUBE_CLIENT_ID", value = var.youtube_client_id },
    { name = "secrets.YOUTUBE_CLIENT_SECRET", value = var.youtube_client_secret },
    { name = "secrets.TIKTOK_CLIENT_ID", value = var.tiktok_client_id },
    { name = "secrets.TIKTOK_CLIENT_SECRET", value = var.tiktok_client_secret },
    { name = "secrets.REDDIT_CLIENT_ID", value = var.reddit_client_id },
    { name = "secrets.REDDIT_CLIENT_SECRET", value = var.reddit_client_secret },
    { name = "secrets.GITHUB_CLIENT_ID", value = var.github_client_id },
    { name = "secrets.GITHUB_CLIENT_SECRET", value = var.github_client_secret },
    { name = "secrets.EMAIL_PASS", value = var.email_pass },
  ]
}
