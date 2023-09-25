resource "cloudflare_record" "cname_www" {
  zone_id = cloudflare_zone.zone.id
  name    = "www"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "www" {
  name = "www-starry-blue"
}

resource "mackerel_monitor" "www" {
  name = format("%s に疎通できない", cloudflare_record.cname_www.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_www.hostname)
    service                = mackerel_service.www.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
