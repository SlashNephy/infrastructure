resource "cloudflare_record" "cname_epgstation" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "epgstation" {
  name = "Lily_EPGStation"
}

resource "mackerel_monitor" "epgstation" {
  name = format("%s に疎通できない", cloudflare_record.cname_epgstation.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_epgstation.hostname)
    service                = mackerel_service.epgstation.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = var.cloudflare_access_client_id
      CF-Access-Client-Secret = var.cloudflare_access_client_secret
    }
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
