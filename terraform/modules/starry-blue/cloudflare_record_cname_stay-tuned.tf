resource "cloudflare_record" "cname_stay_tuned_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "stay-tuned-api"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_stay_tuned_river" {
  zone_id = cloudflare_zone.zone.id
  name    = "stay-tuned-river"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "stay_tuned_api" {
  name = "Lily_stay-tuned-api"
}

resource "mackerel_monitor" "stay_tuned_api" {
  name = cloudflare_record.cname_stay_tuned_api.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/health", cloudflare_record.cname_stay_tuned_api.hostname)
    service                           = mackerel_service.stay_tuned_api.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
