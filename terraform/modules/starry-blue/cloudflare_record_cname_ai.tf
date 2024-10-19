resource "cloudflare_record" "cname_ai" {
  zone_id = cloudflare_zone.zone.id
  name    = "ai"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}
