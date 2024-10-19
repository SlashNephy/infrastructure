resource "cloudflare_record" "txt_keybase_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "_keybase"
  content = "keybase-site-verification=PylHNVjnYCgQBcZdDx7h9AqqtLjNbOw6-qPYrJ5AMlI"
  type    = "TXT"
}
