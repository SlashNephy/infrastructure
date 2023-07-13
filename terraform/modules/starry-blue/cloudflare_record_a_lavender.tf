resource "cloudflare_record" "a_lavender" {
  zone_id = cloudflare_zone.zone.id
  name    = "lavender"
  value   = "140.238.63.30"
  type    = "A"
  proxied = false
}
