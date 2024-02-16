resource "cloudflare_record" "cname_mahiron" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "mahiron" {
  name = "Lily_Mahiron"
}

resource "mackerel_monitor" "mahiron" {
  name = format("%s に疎通できない", cloudflare_record.cname_mahiron.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_mahiron.hostname)
    service                = mackerel_service.mahiron.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = data.onepassword_item.cloudflare_access_client.username
      CF-Access-Client-Secret = data.onepassword_item.cloudflare_access_client.password
    }
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.cloudflare_access_client]
}
