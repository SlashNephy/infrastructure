resource "cloudflare_record" "cname_dns" {
  zone_id = cloudflare_zone.zone.id
  name    = "dns"
  value   = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = false
}
