resource "cloudflare_record" "cname_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "cydia"
  value   = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "cydia" {
  name = "cydia-starry-blue"
}

resource "mackerel_monitor" "cydia" {
  name = format("%s に疎通できない", cloudflare_record.cname_cydia.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_cydia.hostname)
    service                = mackerel_service.cydia.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
