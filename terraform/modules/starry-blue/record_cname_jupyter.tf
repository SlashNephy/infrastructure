resource "cloudflare_record" "cname_jupyter" {
  zone_id = cloudflare_zone.zone.id
  name    = "jupyter"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
