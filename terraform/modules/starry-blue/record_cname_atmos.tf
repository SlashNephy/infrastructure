// TODO: 廃止予定
resource "cloudflare_record" "cname_atmos" {
  zone_id = cloudflare_zone.zone.id
  name    = "atmos"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
