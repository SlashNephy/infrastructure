locals {
  cloudflare_zone_id = "dc3b4dce36437ddabcc6cdcc2d1019f0"
}

resource "cloudflare_dns_record" "cname_root" {
  zone_id = local.cloudflare_zone_id
  name    = "starry.blue"
  content = "gateway.starry.blue"
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Auto
}

resource "cloudflare_dns_record" "cname_www" {
  zone_id = local.cloudflare_zone_id
  name    = "www"
  content = "gateway.starry.blue"
  type    = "CNAME"
  proxied = true
  ttl     = 1 # Auto
}
