resource "cloudflare_record" "cname_stella" {
  zone_id = cloudflare_zone.zone.id
  name    = "stella"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
