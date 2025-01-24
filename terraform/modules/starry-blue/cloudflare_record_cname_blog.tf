resource "cloudflare_record" "cname_blog" {
  zone_id = cloudflare_zone.zone.id
  name    = "blog"
  content = "hatenablog.com"
  type    = "CNAME"
  proxied = false
}

resource "mackerel_service" "blog" {
  name = "blog-starry-blue"
}

resource "mackerel_monitor" "blog" {
  name = cloudflare_record.cname_blog.hostname

  external {
    method                            = "GET"
    url                               = format("https://%s", cloudflare_record.cname_blog.hostname)
    service                           = mackerel_service.blog.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 3
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
