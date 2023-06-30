resource "cloudflare_record" "cname_files" {
  zone_id = cloudflare_zone.zone.id
  name    = "files"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
