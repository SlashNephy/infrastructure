resource "cloudflare_record" "cname_grafana" {
  zone_id = cloudflare_zone.zone.id
  name    = "grafana"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "grafana" {
  name = "Lily_Grafana"
}

resource "mackerel_monitor" "grafana" {
  name = cloudflare_record.cname_grafana.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/api/health", cloudflare_record.cname_grafana.hostname)
    service                           = mackerel_service.grafana.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
