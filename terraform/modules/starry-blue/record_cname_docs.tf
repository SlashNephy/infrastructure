resource "cloudflare_record" "cname_docs" {
  zone_id = cloudflare_zone.zone.id
  name    = "docs"
  value   = "starrybluesky-documents.pages.dev"
  type    = "CNAME"
  proxied = true
}
