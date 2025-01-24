resource "cloudflare_record" "cname_konomitv" {
  zone_id = cloudflare_zone.zone.id
  name    = "konomitv"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "konomitv" {
  name = "Lily_KonomiTV"
}

resource "mackerel_monitor" "konomitv" {
  name = cloudflare_record.cname_konomitv.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/api/version", cloudflare_record.cname_konomitv.hostname)
    service                           = mackerel_service.konomitv.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
