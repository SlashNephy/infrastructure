resource "cloudflare_record" "cname_ai" {
  zone_id = cloudflare_zone.zone.id
  name    = "ai"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
