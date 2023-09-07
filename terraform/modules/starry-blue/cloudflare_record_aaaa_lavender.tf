resource "cloudflare_record" "aaaa_lavender" {
  zone_id = cloudflare_zone.zone.id
  name    = "lavender"
  value   = "2603:c021:800d:63e0:b69c:363e:a3ed:4ace"
  type    = "AAAA"
  proxied = false
}
