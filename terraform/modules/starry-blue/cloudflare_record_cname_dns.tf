resource "cloudflare_record" "cname_dns" {
  zone_id = cloudflare_zone.zone.id
  name    = "dns"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "dns" {
  name = "Lily_AdGuard-Home"
}

resource "mackerel_monitor" "dns" {
  name = cloudflare_record.cname_dns.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_dns.hostname) # TODO
    expected_status_code              = 200
    service                           = mackerel_service.dns.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
