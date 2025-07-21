resource "cloudflare_record" "cname_wol" {
  zone_id = cloudflare_zone.zone.id
  name    = "wol"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "wol" {
  name = "Lily_wolweb"
}

resource "mackerel_monitor" "wol" {
  name = cloudflare_record.cname_wol.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/health", cloudflare_record.cname_wol.hostname)
    expected_status_code              = 200
    service                           = mackerel_service.wol.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
