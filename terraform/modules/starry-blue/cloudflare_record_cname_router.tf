resource "cloudflare_record" "cname_router" {
  zone_id = cloudflare_zone.zone.id
  name    = "router"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}
