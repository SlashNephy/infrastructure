resource "cloudflare_record" "cname_amq_proxy" {
  zone_id = cloudflare_zone.zone.id
  name    = "amq-proxy"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "amq_proxy" {
  name = "Lily_amq-media-proxy"
}

resource "mackerel_monitor" "amq_proxy" {
  name = format("%s に疎通できない", cloudflare_record.cname_amq_proxy.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s/healthcheck", cloudflare_record.cname_amq_proxy.hostname)
    service                           = mackerel_service.amq_proxy.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 3
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
