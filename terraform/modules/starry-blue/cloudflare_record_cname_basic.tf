resource "cloudflare_record" "cname_basic" {
  zone_id = cloudflare_zone.zone.id
  name    = "basic"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
