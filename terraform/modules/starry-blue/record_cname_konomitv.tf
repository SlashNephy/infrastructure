resource "cloudflare_record" "cname_konomitv" {
  zone_id = cloudflare_zone.zone.id
  name    = "konomitv"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
