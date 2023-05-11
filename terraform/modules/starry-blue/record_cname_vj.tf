resource "cloudflare_record" "cname_vj" {
  zone_id = cloudflare_zone.zone.id
  name    = "vj"
  value   = "muni-535.pages.dev"
  type    = "CNAME"
  proxied = true
}
