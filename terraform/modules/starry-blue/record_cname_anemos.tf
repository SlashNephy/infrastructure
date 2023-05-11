// TODO: 廃止予定
resource "cloudflare_record" "cname_anemos" {
  zone_id = cloudflare_zone.zone.id
  name    = "anemos"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
