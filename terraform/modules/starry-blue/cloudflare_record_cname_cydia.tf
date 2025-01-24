resource "cloudflare_record" "cname_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "cydia"
  content = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}
