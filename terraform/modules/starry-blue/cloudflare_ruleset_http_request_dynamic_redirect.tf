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
}
