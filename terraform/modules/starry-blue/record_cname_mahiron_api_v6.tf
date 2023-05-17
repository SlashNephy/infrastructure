resource "cloudflare_record" "cname_mahiron_api_v6" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron-api-v6"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
