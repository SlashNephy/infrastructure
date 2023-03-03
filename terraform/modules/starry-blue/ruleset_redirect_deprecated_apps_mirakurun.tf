resource "cloudflare_ruleset" "redirect_deprecated_apps_mirakurun" {
  zone_id = local.cloudflare_zone_id
  name    = "廃止 (apps.starry.blue/mirakurun)"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled = true
    action  = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://mirakurun.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (starts_with(http.request.full_uri, "https://apps.starry.blue/mirakurun"))
    EOT
  }
}
