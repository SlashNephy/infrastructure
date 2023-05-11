resource "cloudflare_record" "cname_mahiron_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}
