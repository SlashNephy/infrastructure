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
    logging {
      enabled = true
    }

    expression = <<-EOT
      (
        http.host eq "xiv.starry.blue"
        and
        http.request.uri.path contains "/plugins"
        and
        http.user_agent eq ""
      )
    EOT
  }

  rules {
    enabled     = true
    description = "IP Address Based Allow List"
    action      = "block"

    expression = <<-EOT
      (http.host in {
        "xiv-private.starry.blue"
      } and not ip.src in $allow_list)
    EOT
  }
}

resource "cloudflare_list" "allow_list" {
  account_id = cloudflare_account.account.id
  name       = "allow_list"
  kind       = "ip"

  item {
    value {
      ip = "240b:10:3f60:4800::/64"
    }
  }
}
