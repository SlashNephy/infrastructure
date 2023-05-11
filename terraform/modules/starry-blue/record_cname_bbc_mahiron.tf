resource "cloudflare_record" "cname_bbc_mahiron" {
  zone_id         = cloudflare_zone.zone.id
  name            = "bbc-mahiron"
  value           = "4d797d6c-9334-479f-9a9f-a9f378a0a3db.cfargotunnel.com"
  type            = "CNAME"
  proxied         = true
  allow_overwrite = true
}
