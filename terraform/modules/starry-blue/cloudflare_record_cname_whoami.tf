resource "cloudflare_record" "cname_whoami" {
  zone_id = cloudflare_zone.zone.id
  name    = "whoami"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "whoami" {
  name = "Lily_whoami"
}

resource "mackerel_monitor" "whoami" {
  name = cloudflare_record.cname_whoami.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_whoami.hostname)
    service                           = mackerel_service.whoami.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
