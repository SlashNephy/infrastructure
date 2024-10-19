resource "cloudflare_record" "cname_spica" {
  zone_id = cloudflare_zone.zone.id
  name    = "spica"
  content = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "spica" {
  name = "spica-starry-blue"
}

resource "mackerel_monitor" "spica" {
  name = format("%s に疎通できない", cloudflare_record.cname_spica.hostname)

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_spica.hostname)
    service                           = mackerel_service.spica.name
    response_time_warning             = 3000
    response_time_critical            = 5000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }
}
