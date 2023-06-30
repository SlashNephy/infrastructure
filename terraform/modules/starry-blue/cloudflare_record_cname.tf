resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
