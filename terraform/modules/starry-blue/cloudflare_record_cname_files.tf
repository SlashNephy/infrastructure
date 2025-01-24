resource "cloudflare_record" "cname_files" {
  zone_id = cloudflare_zone.zone.id
  name    = "files"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "files" {
  name = "Lily_file-browser"
}

resource "mackerel_monitor" "files" {
  name = cloudflare_record.cname_files.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s/health", cloudflare_record.cname_files.hostname)
    service                           = mackerel_service.files.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}

resource "cloudflare_record" "cname_files_gateway" {
  zone_id = cloudflare_zone.zone.id
  name    = "files.gateway"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
