resource "cloudflare_record" "cname_kubeclarity" {
  zone_id = cloudflare_zone.zone.id
  name    = "kubeclarity"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "kubeclarity" {
  name = "Lily_KubeClarity"
}

resource "mackerel_monitor" "kubeclarity" {
  name = cloudflare_record.cname_kubeclarity.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_kubeclarity.hostname)
    expected_status_code              = 302 # TODO: アプリケーションに到達できるようにし 200 を確認する
    service                           = mackerel_service.kubeclarity.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
