resource "cloudflare_record" "cname_amq_proxy" {
  zone_id = cloudflare_zone.zone.id
  name    = "amq-proxy"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "amq_proxy" {
  name = "Lily_amq-media-proxy"
}

resource "mackerel_monitor" "amq_proxy" {
  name = format("%s に疎通できない", cloudflare_record.cname_amq_proxy.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/healthcheck", cloudflare_record.cname_amq_proxy.hostname)
    service                = mackerel_service.amq_proxy.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = data.onepassword_item.cloudflare_access_client.username
      CF-Access-Client-Secret = data.onepassword_item.cloudflare_access_client.password
    }
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.cloudflare_access_client]
}
