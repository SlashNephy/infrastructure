resource "cloudflare_record" "cname_mirakurun_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "mirakurun-api"
  value   = cloudflare_record.a_gateway_v4.hostname
  type    = "CNAME"
  proxied = false
}
