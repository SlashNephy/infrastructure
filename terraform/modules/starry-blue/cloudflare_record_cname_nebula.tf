resource "cloudflare_record" "cname_nebula_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "nebula-api"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_nebula_river" {
  zone_id = cloudflare_zone.zone.id
  name    = "nebula-river"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "nebula_api" {
  name = "Lily_nebula-server"
}

resource "mackerel_monitor" "nebula_api" {
  name = cloudflare_record.cname_nebula_api.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/health", cloudflare_record.cname_nebula_api.hostname)
    expected_status_code              = 200
    service                           = mackerel_service.nebula_api.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
