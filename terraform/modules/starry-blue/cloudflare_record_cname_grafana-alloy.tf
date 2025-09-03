resource "cloudflare_record" "cname_grafana_alloy" {
  zone_id = cloudflare_zone.zone.id
  name    = "grafana-alloy"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "grafana_alloy" {
  name = "Lily_Grafana-Alloy"
}

resource "mackerel_monitor" "grafana_alloy" {
  name = cloudflare_record.cname_grafana_alloy.hostname

  external {
    method = "GET"
    url    = format("https://%s", cloudflare_record.cname_grafana_alloy.hostname)
    # expected_status_code              = 200
    service                           = mackerel_service.grafana_alloy.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
