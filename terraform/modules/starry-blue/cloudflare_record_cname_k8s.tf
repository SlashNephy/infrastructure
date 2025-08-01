resource "cloudflare_record" "cname_k8s" {
  zone_id = cloudflare_zone.zone.id
  name    = "k8s"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "k8s" {
  name = "Lily_Kubernetes-Dashboard"
}

resource "mackerel_monitor" "k8s" {
  name = cloudflare_record.cname_k8s.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_k8s.hostname)
    expected_status_code              = 302 # TODO: アプリケーションに到達できるようにし 200 を確認する
    service                           = mackerel_service.code.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
