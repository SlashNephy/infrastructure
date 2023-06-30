resource "cloudflare_record" "cname_bbc_k8s" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc-k8s"
  value           = "4d797d6c-9334-479f-9a9f-a9f378a0a3db.cfargotunnel.com"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}

resource "mackerel_service" "bbc_k8s" {
  name = "BBC_Kubernetes-Dashboard"
}

resource "mackerel_monitor" "bbc_k8s" {
  name = format("%s に疎通できない", cloudflare_record.cname_bbc_k8s.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_bbc_k8s.hostname)
    service                = mackerel_service.bbc_k8s.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = var.cloudflare_access_client_id
      CF-Access-Client-Secret = var.cloudflare_access_client_secret
    }
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
