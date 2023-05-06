resource "cloudflare_ruleset" "http_request_dynamic_redirect" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_request_dynamic_redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled     = true
    description = "${cloudflare_record.cname_www.hostname} -> ${cloudflare_record.cname_root.hostname}"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://${cloudflare_record.cname_root.hostname}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "${cloudflare_record.cname_www.hostname}")
    EOT
  }

  rules {
    enabled     = true
    description = "${cloudflare_record.cname_root.hostname} -> ${cloudflare_record.cname_spica.hostname}"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://${cloudflare_record.cname_spica.hostname}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "${cloudflare_record.cname_root.hostname}")
    EOT
  }

  rules {
    enabled     = true
    description = "${cloudflare_record.cname_apps.hostname} -> ${cloudflare_access_organization.starry_blue_sky.auth_domain}"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://${cloudflare_access_organization.starry_blue_sky.auth_domain}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "${cloudflare_record.cname_apps.hostname}" and http.request.uri.path eq "/")
    EOT
  }

  // TODO: 廃止予定
  rules {
    enabled     = true
    description = "廃止 (${cloudflare_record.cname_atmos.hostname})"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://${cloudflare_record.cname_epgstation.hostname}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "${cloudflare_record.cname_atmos.hostname}" and not starts_with(http.request.uri.path, "/mirakurun"))
    EOT
  }
}
