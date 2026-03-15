locals {
  gateway_hostname = "gateway.starry.blue"
}

resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  content = local.gateway_hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_www" {
  zone_id = cloudflare_zone.zone.id
  name    = "www"
  content = local.gateway_hostname
  type    = "CNAME"
  proxied = true
}
