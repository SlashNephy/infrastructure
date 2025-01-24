resource "cloudflare_record" "cname_argocd" {
  zone_id = cloudflare_zone.zone.id
  name    = "argocd"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "argocd" {
  name = "Lily_ArgoCD"
}

resource "mackerel_monitor" "argocd" {
  name = cloudflare_record.cname_argocd.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/healthz", cloudflare_record.cname_argocd.hostname)
    service                           = mackerel_service.argocd.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
