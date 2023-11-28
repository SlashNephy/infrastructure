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
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.lily-mahiron_credential.username, data.onepassword_item.lily-mahiron_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.lily-mahiron_credential]
}
