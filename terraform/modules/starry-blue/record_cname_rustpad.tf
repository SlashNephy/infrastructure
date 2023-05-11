resource "cloudflare_record" "cname_rustpad" {
  zone_id = cloudflare_zone.zone.id
  name    = "rustpad"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
