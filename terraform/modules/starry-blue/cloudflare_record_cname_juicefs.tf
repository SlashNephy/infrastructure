resource "cloudflare_record" "cname_juicefs" {
  zone_id = cloudflare_zone.zone.id
  name    = "juicefs"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "juicefs" {
  name = "Lily_JuiceFS-CSI-Dashboard"
}

resource "mackerel_monitor" "juicefs" {
  name = format("%s に疎通できない", cloudflare_record.cname_juicefs.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_juicefs.hostname)
    service                           = mackerel_service.code.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
