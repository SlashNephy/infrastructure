resource "cloudflare_record" "cname_asf" {
  zone_id = cloudflare_zone.zone.id
  name    = "asf"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "asf" {
  name = "Lily_ArchSteamFarm"
}

resource "mackerel_monitor" "asf" {
  name = cloudflare_record.cname_asf.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/healthcheck", cloudflare_record.cname_asf.hostname)
    expected_status_code              = 200
    service                           = mackerel_service.asf.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
