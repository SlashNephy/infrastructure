resource "cloudflare_record" "cname_blog" {
  zone_id = cloudflare_zone.zone.id
  name    = "blog"
  value   = "hatenablog.com"
  type    = "CNAME"
  proxied = false
}

resource "mackerel_service" "blog" {
  name = "blog-starry-blue"
}

resource "mackerel_monitor" "blog" {
  name = format("%s に疎通できない", cloudflare_record.cname_blog.hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", cloudflare_record.cname_blog.hostname)
    service                = mackerel_service.blog.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
    }
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
