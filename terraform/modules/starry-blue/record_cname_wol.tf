resource "cloudflare_record" "cname_wol" {
  zone_id = cloudflare_zone.zone.id
  name    = "wol"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
