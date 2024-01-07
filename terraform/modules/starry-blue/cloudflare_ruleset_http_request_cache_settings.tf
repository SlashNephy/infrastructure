resource "cloudflare_ruleset" "http_request_cache_settings" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_request_cache_settings"
  kind    = "zone"
  phase   = "http_request_cache_settings"

  rules {
    enabled     = true
    description = "Enable Cache behind Cloudflare Access"
    action      = "set_cache_settings"
    action_parameters {
      cache = true
      edge_ttl {
        mode = "respect_origin"
      }
      browser_ttl {
        mode = "respect_origin"
      }
      serve_stale {
        disable_stale_while_updating = false
      }
      respect_strong_etags       = false
      cache_key {}
      origin_error_page_passthru = false
    }

    expression = <<-EOT
      ssl and (http.host in {
        "${cloudflare_record.cname_amq_proxy.hostname}"
      })
    EOT
  }
}
