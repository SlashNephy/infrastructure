resource "cloudflare_record" "cname_blog" {
  zone_id = cloudflare_zone.zone.id
  name    = "blog"
  content = "hatenablog.com"
  type    = "CNAME"
  proxied = false
}
