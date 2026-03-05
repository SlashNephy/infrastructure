resource "cloudflare_record" "cname_n8n" {
  zone_id = cloudflare_zone.zone.id
  name    = "n8n"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "n8n" {
  name = "Lily_n8n"
}

resource "mackerel_monitor" "n8n" {
  name = cloudflare_record.cname_n8n.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/healthz", cloudflare_record.cname_n8n.hostname)
    expected_status_code              = 200
    service                           = mackerel_service.n8n.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
