resource "cloudflare_record" "cname_influxdb" {
  zone_id = cloudflare_zone.zone.id
  name    = "influxdb"
  content = cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}
