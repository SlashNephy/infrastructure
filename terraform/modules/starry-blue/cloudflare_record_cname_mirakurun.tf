resource "cloudflare_record" "cname_mirakurun" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "mirakurun" {
  name = "Lily_Mirakurun"
}

resource "mackerel_monitor" "mirakurun" {
  name = format("%s に疎通できない", cloudflare_record.cname_mirakurun.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_mirakurun.hostname)
    service                = mackerel_service.mirakurun.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = data.onepassword_item.cloudflare_access_client.username
      CF-Access-Client-Secret = data.onepassword_item.cloudflare_access_client.password
    }
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.cloudflare_access_client]
}
