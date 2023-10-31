resource "cloudflare_ruleset" "http_request_firewall_custom" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_request_firewall_custom"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    enabled     = true
    description = "Skip WAF Protection"
    action      = "skip"
    action_parameters {
      phases = [
        "http_ratelimit",
        "http_request_firewall_managed",
        "http_request_sbfm"
      ]
      products = [
        "rateLimit",
        "waf",
        "securityLevel",
        "hot",
        "bic",
        "uaBlock",
        "zoneLockdown"
      ]
    }

    expression = <<-EOT
      (http.host in {
        "xiv.starry.blue"
      })
    EOT
  }

  rules {
    enabled     = true
    description = "IP Address Based Allow List"
    action      = "block"

    expression = <<-EOT
      (http.host in {
        "xiv-private.starry.blue"
      } and not ip.src in {
        240b:10:3f60:4800:dc56:f7de:5e49:2203
      })
    EOT
  }
}
