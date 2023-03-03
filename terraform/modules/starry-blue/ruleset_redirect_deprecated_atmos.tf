resource "cloudflare_ruleset" "redirect_deprecated_atmos" {
  zone_id = local.cloudflare_zone_id
  name    = "廃止 (atmos.starry.blue)"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled = true
    action  = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://epgstation.starry.blue"
        }
        preserve_query_string = false
      }
    }

    # TODO: /mirakurun 廃止後、式を更新する
    expression = <<-EOT
      (http.host eq "atmos.starry.blue" and not starts_with(http.request.uri.path, "/mirakurun"))
    EOT
  }
}
