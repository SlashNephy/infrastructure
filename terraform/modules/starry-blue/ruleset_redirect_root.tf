resource "cloudflare_ruleset" "redirect_root" {
  zone_id = local.cloudflare_zone_id
  name    = "starry.blue -> spica.starry.blue"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled = true
    action  = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://spica.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "starry.blue")
    EOT
  }
}
