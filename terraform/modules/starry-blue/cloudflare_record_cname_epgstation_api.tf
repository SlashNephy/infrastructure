resource "cloudflare_record" "cname_epgstation_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}

resource "mackerel_service" "epgstation_api" {
  name = "Lily_EPGStation-API"
}

resource "mackerel_monitor" "epgstation_api" {
  name = format("%s に疎通できない", cloudflare_record.cname_epgstation_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s:13444/api/version", cloudflare_record.cname_epgstation_api.hostname)
    service                = mackerel_service.epgstation_api.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.basic_credentials["lily-epgstation"].user, var.basic_credentials["lily-epgstation"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
