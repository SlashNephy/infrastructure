resource "cloudflare_record" "cname_traefik" {
  zone_id = cloudflare_zone.zone.id
  name    = "traefik"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "traefik" {
  name = "Lily_Traefik"
}

resource "mackerel_monitor" "traefik" {
  name = cloudflare_record.cname_traefik.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_traefik.hostname)
    expected_status_code              = 302 # TODO: アプリケーションに到達できるようにし 200 を確認する
    service                           = mackerel_service.traefik.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
