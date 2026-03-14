resource "cloudflare_record" "cname_headlessx" {
  zone_id = cloudflare_zone.zone.id
  name    = "headlessx"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}

resource "cloudflare_record" "cname_headlessx_api" {
  zone_id = cloudflare_zone.zone.id
  name    = "headlessx-api"
  content = data.cloudflare_record.aaaa_gateway_v6.hostname
  type    = "CNAME"
  proxied = true
}
