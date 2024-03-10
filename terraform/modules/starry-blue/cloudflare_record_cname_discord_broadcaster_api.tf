resource "cloudflare_record" "cname_discord_broadcaster_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "discord-broadcaster-api"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "discord-broadcaster" {
  name = "Lily_discord-broadcaster"
}

resource "mackerel_monitor" "discord-broadcaster" {
  name = format("%s に疎通できない", cloudflare_record.cname_discord_broadcaster_api.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/status", cloudflare_record.cname_discord_broadcaster_api.hostname)
    service                = mackerel_service.discord-broadcaster.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
