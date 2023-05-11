resource "cloudflare_record" "cname_code" {
  zone_id = cloudflare_zone.zone.id
  name    = "code"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
