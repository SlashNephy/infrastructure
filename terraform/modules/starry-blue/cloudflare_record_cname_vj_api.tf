resource "cloudflare_record" "cname_vj_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "vj-api"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
