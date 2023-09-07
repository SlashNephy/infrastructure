resource "cloudflare_record" "a_lavender" {
  zone_id = cloudflare_zone.zone.id
  name    = "lavender"
  value   = "152.70.108.21"
  type    = "A"
  proxied = false
}
