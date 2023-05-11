resource "cloudflare_record" "cname_feed" {
  zone_id = cloudflare_zone.zone.id
  name    = "feed"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
