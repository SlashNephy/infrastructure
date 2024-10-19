resource "cloudflare_record" "cname_epgstation_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "epgstation-api"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
