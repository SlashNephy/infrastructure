resource "cloudflare_ruleset" "redirect_apps" {
  zone_id = local.cloudflare_zone_id
  name    = "apps.starry.blue -> ${local.cloudflare_access_domain}"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled = true
    action  = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://${local.cloudflare_access_domain}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "apps.starry.blue" and http.request.uri.path eq "/")
    EOT
  }
}
