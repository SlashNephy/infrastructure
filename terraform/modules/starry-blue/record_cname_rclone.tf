resource "cloudflare_record" "cname_rclone" {
  zone_id = cloudflare_zone.zone.id
  name    = "rclone"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
