resource "cloudflare_record" "a_gateway" {
  zone_id         = cloudflare_zone.zone.id
  name            = "gateway-v4"
  type            = "A"
  proxied         = false
  allow_overwrite = true
}
