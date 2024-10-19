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
  name = format("%s に疎通できない", cloudflare_record.cname_komga.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_komga.hostname)
    service                           = mackerel_service.komga.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
