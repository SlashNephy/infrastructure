resource "cloudflare_record" "cname_maaya" {
  zone_id = cloudflare_zone.zone.id
  name    = "maaya"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
