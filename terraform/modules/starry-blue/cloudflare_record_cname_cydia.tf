resource "cloudflare_record" "cname_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "cydia"
  value   = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}
