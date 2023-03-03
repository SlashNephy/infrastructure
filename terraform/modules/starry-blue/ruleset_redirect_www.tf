resource "cloudflare_ruleset" "redirect_www" {
  zone_id = local.cloudflare_zone_id
  name    = "www.starry.blue -> starry.blue"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled = true
    action  = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "www.starry.blue")
    EOT
  }
}
