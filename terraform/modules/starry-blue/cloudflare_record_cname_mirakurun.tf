// Deprecated: mahiron.starry.blue にリダイレクトされる
resource "cloudflare_record" "cname_mirakurun" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
