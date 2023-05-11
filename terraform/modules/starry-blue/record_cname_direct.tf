// 互換性のために残す
resource "cloudflare_record" "cname_direct" {
  zone_id = cloudflare_zone.zone.id
  name    = "direct"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = false
}
