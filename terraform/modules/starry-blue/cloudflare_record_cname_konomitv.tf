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
  name = format("%s に疎通できない", cloudflare_record.cname_konomitv.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s/api/version", cloudflare_record.cname_konomitv.hostname)
    service                           = mackerel_service.konomitv.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
