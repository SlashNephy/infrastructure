resource "cloudflare_record" "cname_epgstation_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}
