resource "cloudflare_record" "cname_inori" {
  zone_id = cloudflare_zone.zone.id
  name    = "inori"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
