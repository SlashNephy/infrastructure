data "cloudflare_record" "aaaa_gateway_v6" {
  zone_id  = cloudflare_zone.zone.id
  type     = "AAAA"
  hostname = "gateway-v6.starry.blue"
}
