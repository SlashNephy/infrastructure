resource "cloudflare_record" "cname_kubeclarity" {
  zone_id = cloudflare_zone.zone.id
  name    = "kubeclarity"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "kubeclarity" {
  name = "Lily_KubeClarity"
}

resource "mackerel_monitor" "kubeclarity" {
  name = format("%s に疎通できない", cloudflare_record.cname_kubeclarity.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_kubeclarity.hostname)
    service                = mackerel_service.kubeclarity.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = data.onepassword_item.cloudflare_access_client.username
      CF-Access-Client-Secret = data.onepassword_item.cloudflare_access_client.password
    }
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.cloudflare_access_client]
}
