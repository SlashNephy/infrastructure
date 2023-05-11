resource "cloudflare_record" "cname_apps" {
  zone_id = cloudflare_zone.zone.id
  name    = "apps"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
