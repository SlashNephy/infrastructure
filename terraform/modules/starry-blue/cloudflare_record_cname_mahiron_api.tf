resource "cloudflare_record" "cname_mahiron_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron-api"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
