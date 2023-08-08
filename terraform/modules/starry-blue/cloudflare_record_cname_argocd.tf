resource "cloudflare_record" "cname_argocd" {
  zone_id = cloudflare_zone.zone.id
  name    = "argocd"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "argocd" {
  name = "Lily_ArgoCD"
}

resource "mackerel_monitor" "argocd" {
  name = format("%s に疎通できない", cloudflare_record.cname_argocd.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_argocd.hostname)
    service                = mackerel_service.argocd.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = var.cloudflare_access_client_id
      CF-Access-Client-Secret = var.cloudflare_access_client_secret
    }
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
