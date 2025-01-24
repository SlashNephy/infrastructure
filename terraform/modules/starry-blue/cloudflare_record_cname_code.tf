resource "cloudflare_record" "cname_code" {
  zone_id = cloudflare_zone.zone.id
  name    = "code"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "code" {
  name = "Lily_code-server"
}

resource "mackerel_monitor" "code" {
  name = cloudflare_record.cname_code.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/healthz", cloudflare_record.cname_code.hostname)
    service                           = mackerel_service.code.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
