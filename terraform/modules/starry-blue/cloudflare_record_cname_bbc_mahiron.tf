resource "cloudflare_record" "cname_bbc_mahiron" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc-mahiron"
  value           = "4d797d6c-9334-479f-9a9f-a9f378a0a3db.cfargotunnel.com"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "mackerel_service" "bbc_mahiron" {
  name = "BBC_Mahiron"
}

resource "mackerel_monitor" "bbc_mahiron" {
  name = format("%s に疎通できない", cloudflare_record.cname_bbc_mahiron.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_bbc_mahiron.hostname)
    service                = mackerel_service.bbc_mahiron.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = var.cloudflare_access_client_id
      CF-Access-Client-Secret = var.cloudflare_access_client_secret
    }
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
