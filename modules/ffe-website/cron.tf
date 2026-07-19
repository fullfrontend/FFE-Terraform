resource "kubernetes_cron_job_v1" "wordpress_cron" {
  count = var.private_guides_storage_size != "" ? 1 : 0

  metadata {
    name      = "wordpress-cron"
    namespace = kubernetes_namespace.wordpress.metadata[0].name
    labels = {
      app = "ffe-website"
    }
  }

  spec {
    schedule                      = "* * * * *"
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 1
    failed_jobs_history_limit     = 3

    job_template {
      metadata {
        labels = {
          app = "ffe-website-cron"
        }
      }

      spec {
        backoff_limit              = 2
        ttl_seconds_after_finished = 300

        template {
          metadata {
            labels = {
              app = "ffe-website-cron"
            }
          }

          spec {
            restart_policy = "Never"

            container {
              name    = "wp-cron"
              image   = "curlimages/curl:8.16.0"
              command = ["curl"]
              args = [
                "--fail",
                "--silent",
                "--show-error",
                "--max-time",
                "50",
                "http://wordpress.${var.namespace}.svc.cluster.local/wp-cron.php?doing_wp_cron",
              ]

              resources {
                requests = {
                  cpu    = "5m"
                  memory = "8Mi"
                }
                limits = {
                  cpu    = "50m"
                  memory = "32Mi"
                }
              }
            }
          }
        }
      }
    }
  }
}
