resource "cloudflare_record" "cname_epgstation" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "epgstation" {
  name = "Lily_EPGStation"
}

resource "mackerel_monitor" "epgstation" {
  name = cloudflare_record.cname_epgstation.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/api/version", cloudflare_record.cname_epgstation.hostname)
    service                           = mackerel_service.epgstation.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 3
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
