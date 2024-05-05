resource "cloudflare_record" "cname_asf" {
  zone_id = cloudflare_zone.zone.id
  name    = "asf"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "asf" {
  name = "Lily_ArchSteamFarm"
}

resource "mackerel_monitor" "asf" {
  name = format("%s に疎通できない", cloudflare_record.cname_asf.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s/healthcheck", cloudflare_record.cname_asf.hostname)
    service                           = mackerel_service.asf.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
