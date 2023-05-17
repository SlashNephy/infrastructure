resource "cloudflare_record" "aaaa_gateway_v6" {
  zone_id         = cloudflare_zone.zone.id
  name            = "gateway-v6"
  type            = "AAAA"
  proxied         = false
  allow_overwrite = true
}
