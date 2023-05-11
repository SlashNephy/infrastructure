resource "cloudflare_record" "cname_omikuji" {
  zone_id = cloudflare_zone.zone.id
  name    = "omikuji"
  value   = "anime-omikuji.pages.dev"
  type    = "CNAME"
  proxied = true
}
