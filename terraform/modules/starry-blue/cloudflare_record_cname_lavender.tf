resource "cloudflare_record" "cname_lavender" {
  zone_id = cloudflare_zone.zone.id
  name    = "lavender"
  value   = "lavender.subnet07242144.vcn07242144.oraclevcn.com"
  type    = "CNAME"
  proxied = false
}
