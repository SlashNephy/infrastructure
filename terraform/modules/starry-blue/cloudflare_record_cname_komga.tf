resource "cloudflare_record" "cname_komga" {
  zone_id = cloudflare_zone.zone.id
  name    = "komga"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "komga" {
  name = "Lily_Komga"
}

resource "mackerel_monitor" "komga" {
  name = cloudflare_record.cname_komga.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_komga.hostname)
    service                           = mackerel_service.komga.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
