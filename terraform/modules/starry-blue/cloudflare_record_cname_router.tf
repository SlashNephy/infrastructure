resource "cloudflare_record" "cname_router" {
  zone_id = cloudflare_zone.zone.id
  name    = "router"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
