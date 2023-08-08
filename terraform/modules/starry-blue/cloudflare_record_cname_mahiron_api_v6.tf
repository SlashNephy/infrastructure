resource "cloudflare_record" "cname_mahiron_api_v6" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron-api-v6"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}

resource "mackerel_service" "mahiron_api_v6" {
  name = "Lily_Mahiron-API-IPv6"
}

resource "mackerel_monitor" "mahiron_api_v6" {
  name = format("%s に疎通できない", cloudflare_record.cname_mahiron_api_v6.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/api/status", cloudflare_record.cname_mahiron_api_v6.hostname)
    service                = mackerel_service.mahiron_api_v6.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.basic_credentials["lily-mirakurun"].user, var.basic_credentials["lily-mirakurun"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
