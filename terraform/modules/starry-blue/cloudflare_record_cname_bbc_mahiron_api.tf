resource "cloudflare_record" "cname_bbc_mahiron_api" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc-mahiron-api"
  value           = "4d797d6c-9334-479f-9a9f-a9f378a0a3db.cfargotunnel.com"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "mackerel_service" "bbc_mahiron_api" {
  name = "BBC_Mahiron-API"
}

resource "mackerel_monitor" "bbc_mahiron_api" {
  name = format("%s に疎通できない", cloudflare_record.cname_bbc_mahiron_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/api/status", cloudflare_record.cname_bbc_mahiron_api.hostname)
    service                = mackerel_service.bbc_mahiron_api.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.bbc-mahiron_credential.username, data.onepassword_item.bbc-mahiron_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.bbc-mahiron_credential]
}
