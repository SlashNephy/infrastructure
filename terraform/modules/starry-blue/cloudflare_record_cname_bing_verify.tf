resource "cloudflare_record" "cname_bing_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "e16b9629e876c719a2f86c33b2a3194c"
  content = "verify.bing.com"
  type    = "CNAME"
  proxied = true
}
