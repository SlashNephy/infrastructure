resource "cloudflare_record" "cname_photos" {
  zone_id = cloudflare_zone.zone.id
  name    = "photos"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "photos" {
  name = "Lily_PhotoPrism"
}

resource "mackerel_monitor" "photos" {
  name = cloudflare_record.cname_photos.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_photos.hostname)
    service                           = mackerel_service.photos.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
