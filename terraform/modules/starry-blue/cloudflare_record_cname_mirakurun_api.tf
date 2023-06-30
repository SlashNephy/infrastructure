resource "cloudflare_record" "cname_mirakurun_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}

resource "mackerel_service" "mirakurun_api" {
  name = "Lily_Mirakurun-API"
}

resource "mackerel_monitor" "mirakurun_api" {
  name = format("%s に疎通できない", cloudflare_record.cname_mirakurun_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s:13444/api/status", cloudflare_record.cname_mirakurun_api.hostname)
    service                = mackerel_service.mirakurun_api.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.basic_credentials["lily-mirakurun"].user, var.basic_credentials["lily-mirakurun"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
