resource "cloudflare_record" "cname_traefik" {
  zone_id = cloudflare_zone.zone.id
  name    = "traefik"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
