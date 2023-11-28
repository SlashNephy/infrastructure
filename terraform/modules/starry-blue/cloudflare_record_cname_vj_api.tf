resource "cloudflare_record" "cname_vj_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "vj-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "vj_api" {
  name = "Lily_Muni-Backend"
}

resource "mackerel_monitor" "vj_api" {
  name = format("%s に疎通できない", cloudflare_record.cname_vj_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_vj_api.hostname)
    service                = mackerel_service.vj_api.name
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
