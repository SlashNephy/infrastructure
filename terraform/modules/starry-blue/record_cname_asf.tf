resource "cloudflare_record" "cname_asf" {
  zone_id = cloudflare_zone.zone.id
  name    = "asf"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
