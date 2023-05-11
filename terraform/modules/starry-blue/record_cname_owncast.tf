resource "cloudflare_record" "cname_owncast" {
  zone_id = cloudflare_zone.zone.id
  name    = "owncast"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
