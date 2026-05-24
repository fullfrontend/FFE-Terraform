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
        client_max_body_size 5g;

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
      # Match Traefik's WAF middleware body limit. This is required for large
      # WebDAV uploads; otherwise ModSecurity/Apache returns 413 before the
      # OpenCloud host bypass rule can help.
      LimitRequestBody 0
      SecRequestBodyLimit ${var.waf_max_body_size}
      SecRequestBodyNoFilesLimit ${var.waf_max_body_size}
      SecRequestBodyLimitAction Reject

      # The WAF subrequest is handled by Apache before it reaches the dummy
      # backend. WebDAV/TUS clients legitimately send conditional headers, but
      # Apache evaluates If-Match against the WAF URL itself and returns 412.
      # Strip them only from the WAF inspection request; Traefik still forwards
      # the original headers to OpenCloud.
      RequestHeader unset If-Match early
      RequestHeader unset If-None-Match early
      RequestHeader unset If-Modified-Since early
      RequestHeader unset If-Unmodified-Since early

      # WordPress media uploads legitimately send image payloads that CRS 920420
      # flags as unsupported content types. Let WordPress handle those endpoints.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@pm fullfrontend.be www.fullfrontend.be" \
        "id:1001000,phase:1,pass,nolog,t:none,chain"
      SecRule REQUEST_URI "@rx ^/(wp-admin/async-upload\\.php|wp-admin/admin-ajax\\.php|wp-json/wp/v2/media|wp-json/elementor/.*)$" \
        "t:none,setvar:'tx.allowed_request_content_type=|application/x-www-form-urlencoded| |multipart/form-data| |text/xml| |application/xml| |application/soap+xml| |application/json| |image/jpeg| |image/png| |image/gif| |image/webp| |image/svg+xml| |application/zip| |application/x-zip-compressed| |application/gzip| |application/x-gzip| |application/x-tar| |application/octet-stream|',ctl:ruleRemoveById=920420"

      # OpenCloud relies heavily on WebDAV/CardDAV/CalDAV semantics, custom methods,
      # special headers such as Lock-Token / If, and binary uploads. Keeping CRS
      # enabled there creates fragile false positives, so bypass WAF for this host.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@streq cloud.fullfrontend.be" \
        "id:1001001,phase:1,allow,nolog,t:none,ctl:ruleEngine=Off"

      # Twenty sends GraphQL payloads to /metadata and other JSON endpoints that
      # CRS regularly misclassifies as command injection. Let the application
      # validate those requests directly.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@streq crm.fullfrontend.be" \
        "id:1001003,phase:1,allow,nolog,t:none,ctl:ruleEngine=Off"

      # n8n workflow saves and executions send arbitrary user-authored JSON/JS
      # snippets. CRS blocks legitimate workflow payloads, so let n8n enforce
      # auth and validation for both the editor and webhook hosts.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@pm n8n.fullfrontend.be webhook.fullfrontend.be" \
        "id:1001004,phase:1,allow,nolog,t:none,ctl:ruleEngine=Off"

      # FRP tunnels may expose arbitrary application payloads. The social host
      # must pass through untouched; let the service behind the tunnel enforce
      # its own validation and authentication.
      SecRule REQUEST_HEADERS:X-Forwarded-Host "@streq social.fullfrontend.be" \
        "id:1001005,phase:1,allow,nolog,t:none,ctl:ruleEngine=Off"

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

          env {
            name  = "MODSEC_REQ_BODY_LIMIT"
            value = tostring(var.waf_max_body_size)
          }

          env {
            name  = "MODSEC_REQ_BODY_NOFILES_LIMIT"
            value = tostring(var.waf_max_body_size)
          }

          env {
            name  = "MODSEC_REQ_BODY_LIMIT_ACTION"
            value = "Reject"
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
