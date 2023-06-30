resource "cloudflare_record" "cname_www" {
  zone_id = cloudflare_zone.zone.id
  name    = "www"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
