resource "cloudflare_record" "cname_epgstation_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation-api"
  value   = cloudflare_record.a_gateway_v4.hostname
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
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.lily-epgstation_credential.username, data.onepassword_item.lily-epgstation_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.lily-epgstation_credential]
}
