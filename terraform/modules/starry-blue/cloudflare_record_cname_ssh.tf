resource "cloudflare_record" "cname_ssh" {
  zone_id         = cloudflare_zone.zone.id
  name            = "ssh"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}
