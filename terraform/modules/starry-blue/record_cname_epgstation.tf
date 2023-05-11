resource "cloudflare_record" "cname_epgstation" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
