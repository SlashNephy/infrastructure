resource "cloudflare_record" "cname_whoami" {
  zone_id = cloudflare_zone.zone.id
  name    = "whoami"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
