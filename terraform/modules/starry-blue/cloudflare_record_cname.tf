resource "cloudflare_record" "cname_root" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}
