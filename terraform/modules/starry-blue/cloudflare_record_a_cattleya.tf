resource "cloudflare_record" "a_cattleya" {
  zone_id = cloudflare_zone.zone.id
  name    = "cattleya"
  value   = "192.168.1.3"
  type    = "A"
  proxied = false
}
