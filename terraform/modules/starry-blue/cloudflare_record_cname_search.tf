resource "cloudflare_record" "cname_search" {
  zone_id = cloudflare_zone.zone.id
  name    = "search"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
