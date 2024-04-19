resource "cloudflare_record" "cname_files" {
  zone_id = cloudflare_zone.zone.id
  name    = "files"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "files" {
  name = "Lily_file-browser"
}

resource "mackerel_monitor" "files" {
  name = format("%s に疎通できない", cloudflare_record.cname_files.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_files.hostname)
    service                = mackerel_service.files.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 1
    headers = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.cloudflare_access_client]
}
