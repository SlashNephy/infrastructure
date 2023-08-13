resource "cloudflare_record" "cname_rclone" {
  zone_id = cloudflare_zone.zone.id
  name    = "rclone"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}

resource "mackerel_service" "rclone_radio" {
  name = "Lily_rclone-radio"
}

resource "mackerel_monitor" "rclone_radio" {
  name = format("%s/radio に疎通できない", cloudflare_record.cname_rclone.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/radio", cloudflare_record.cname_rclone.hostname)
    service                = mackerel_service.rclone_radio.name
    response_time_warning  = 500
    response_time_critical = 1000
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

resource "mackerel_service" "rclone_records" {
  name = "rclone-records"
}

resource "mackerel_monitor" "rclone_records" {
  name = format("%s に疎通できない (records)", cloudflare_record.cname_rclone.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s/records", cloudflare_record.cname_rclone.hostname)
    service                = mackerel_service.rclone_records.name
    response_time_warning  = 500
    response_time_critical = 1000
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
