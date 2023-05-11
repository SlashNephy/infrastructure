resource "cloudflare_record" "a_lily" {
  zone_id = cloudflare_zone.zone.id
  name    = "lily"
  value   = "192.168.0.2"
  type    = "A"
  proxied = false
}
