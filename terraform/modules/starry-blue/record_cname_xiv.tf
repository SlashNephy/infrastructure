resource "cloudflare_record" "cname_xiv" {
  zone_id = cloudflare_zone.zone.id
  name    = "xiv"
  value   = "divination.pages.dev"
  type    = "CNAME"
  proxied = true
}
