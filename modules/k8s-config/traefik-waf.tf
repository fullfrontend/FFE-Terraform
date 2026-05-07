/*
    Global WAF via Traefik plugin (ModSecurity + OWASP CRS)
    - ModSecurity container acts as inspection engine
    - Dummy upstream must always answer 200 on any path so Traefik can continue to the real backend
*/
resource "kubernetes_config_map" "waf_dummy_nginx" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-dummy-nginx"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    "default.conf" = <<-EOF
      server {
        listen 80 default_server;
        server_name _;

        location / {
          add_header Content-Type text/plain;
          return 200 "ok\n";
        }
      }
    EOF
  }
}

resource "kubernetes_config_map" "waf_modsecurity_override" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-modsecurity-override"
    namespace = kubernetes_namespace.infra.metadata[0].name
  }

  data = {
    "modsecurity-override.conf" = <<-EOF
      # OpenCloud relies heavily on WebDAV/CardDAV/CalDAV semantics, custom methods and
      # special headers such as Lock-Token / If. Keeping CRS enabled there creates
      # repeated false positives. Bypass the WAF for this single hostname.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@streq cloud.fullfrontend.be" \
        "id:1001001,phase:1,pass,nolog,t:none,ctl:ruleEngine=Off"

      # Vince analytics posts JSON payloads with text/plain; allow it only on the analytics frontend.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@streq insights.fullfrontend.be" \
        "id:1001002,phase:1,pass,nolog,t:none,\
        setvar:'tx.allowed_request_content_type=|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/soap+xml| |application/json| |text/plain|'"
    EOF
  }
}

resource "kubernetes_deployment" "waf_dummy" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-dummy"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-dummy"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "waf-dummy"
      }
    }

    template {
      metadata {
        labels = {
          app = "waf-dummy"
        }
      }

      spec {
        container {
          name  = "waf-dummy"
          image = var.waf_dummy_image

          port {
            name           = "http"
            container_port = 80
          }

          volume_mount {
            name       = "nginx-config"
            mount_path = "/etc/nginx/conf.d/default.conf"
            sub_path   = "default.conf"
            read_only  = true
          }
        }

        volume {
          name = "nginx-config"

          config_map {
            name = kubernetes_config_map.waf_dummy_nginx[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "waf_dummy" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-dummy"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-dummy"
    }
  }

  spec {
    selector = {
      app = "waf-dummy"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_deployment" "waf_modsecurity" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-modsecurity"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-modsecurity"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "waf-modsecurity"
      }
    }

    template {
      metadata {
        labels = {
          app = "waf-modsecurity"
        }
      }

      spec {
        container {
          name  = "waf-modsecurity"
          image = var.waf_modsecurity_image

          env {
            name  = "BACKEND"
            value = "http://waf-dummy.${kubernetes_namespace.infra.metadata[0].name}.svc.cluster.local"
          }

          port {
            name           = "http"
            container_port = 8080
          }

          volume_mount {
            name       = "modsecurity-override"
            mount_path = "/etc/modsecurity.d/modsecurity-override.conf"
            sub_path   = "modsecurity-override.conf"
            read_only  = true
          }
        }

        volume {
          name = "modsecurity-override"

          config_map {
            name = kubernetes_config_map.waf_modsecurity_override[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "waf_modsecurity" {
  count = var.is_prod && var.enable_waf ? 1 : 0

  metadata {
    name      = "waf-modsecurity"
    namespace = kubernetes_namespace.infra.metadata[0].name
    labels = {
      app = "waf-modsecurity"
    }
  }

  spec {
    selector = {
      app = "waf-modsecurity"
    }

    port {
      name        = "http"
      port        = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_manifest" "waf_middleware" {
  count      = var.is_prod && var.enable_waf ? 1 : 0
  depends_on = [helm_release.traefik]

  manifest = {
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"
    metadata = {
      name      = "waf"
      namespace = kubernetes_namespace.infra.metadata[0].name
    }
    spec = {
      plugin = {
        modsecurity = {
          modSecurityUrl = "http://waf-modsecurity.${kubernetes_namespace.infra.metadata[0].name}.svc.cluster.local"
          maxBodySize    = var.waf_max_body_size
          timeoutMillis  = var.waf_timeout_ms
        }
      }
    }
  }
}
