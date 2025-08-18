resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_wildcard" {
  zone_id = cloudflare_zone.zone.id
  name    = "*"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_wildcard_gateway" {
  zone_id = cloudflare_zone.zone.id
  name    = "*.gateway"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
