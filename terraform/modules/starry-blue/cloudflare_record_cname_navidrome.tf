resource "cloudflare_record" "cname_navidrome" {
  zone_id = cloudflare_zone.zone.id
  name    = "navidrome"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "navidrome" {
  name = "Lily_Navidrome"
}

resource "mackerel_monitor" "navidrome" {
  name = cloudflare_record.cname_navidrome.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/ping", cloudflare_record.cname_navidrome.hostname)
    service                           = mackerel_service.navidrome.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
