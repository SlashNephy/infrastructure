resource "cloudflare_ruleset" "http_response_headers_transform" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_response_headers_transform"
  kind    = "zone"
  phase   = "http_response_headers_transform"

  rules {
    enabled     = true
    description = "Enable CORS behind Cloudflare Access"
    action      = "rewrite"
    action_parameters {
      headers {
        name      = "Access-Control-Allow-Credentials"
        value     = "true"
        operation = "set"
      }
    }

    expression = <<-EOT
      ssl and (http.host in {
        "${cloudflare_record.cname_amq_proxy.hostname}"
      })
    EOT
  }
}
