resource "cloudflare_record" "cname_mahiron" {
  zone_id = cloudflare_zone.zone.id
  name    = "mahiron"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
