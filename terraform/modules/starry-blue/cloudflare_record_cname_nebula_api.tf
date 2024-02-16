resource "cloudflare_record" "cname_nebula_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "nebula-api"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "nebula_api" {
  name = "Lily_nebula-server"
}

resource "mackerel_monitor" "nebula_api" {
  name = format("%s に疎通できない", cloudflare_record.cname_nebula_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/health", cloudflare_record.cname_nebula_api.hostname)
    service                = mackerel_service.nebula_api.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
