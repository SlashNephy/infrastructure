resource "cloudflare_record" "cname_spica" {
  zone_id = cloudflare_zone.zone.id
  name    = "spica"
  value   = "slashnephy.github.io"
  type    = "CNAME"
  proxied = true
}
