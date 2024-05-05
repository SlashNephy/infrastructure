resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "root" {
  name = "starry-blue"
}

resource "mackerel_monitor" "root" {
  name = format("%s に疎通できない", cloudflare_record.cname_root.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_root.hostname)
    service                           = mackerel_service.root.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
