resource "cloudflare_record" "txt_spf" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "v=spf1 include:_spf.mx.cloudflare.net ~all"
  type    = "TXT"
}

resource "cloudflare_record" "txt_dmarc" {
  zone_id = cloudflare_zone.zone.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=quarantine; rua=mailto:${local.webmaster_email_address}"
  type    = "TXT"
}

resource "cloudflare_record" "txt_google_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "google-site-verification=CqG0H3T0SQtGDVumMvFz0u6N_W0QrsN_rHFlIC4_y1U"
  type    = "TXT"
}

resource "cloudflare_record" "txt_github_verify_starrybluesky" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-challenge-starrybluesky"
  value   = "0f0c3cea54"
  type    = "TXT"
}

resource "cloudflare_record" "txt_github_verify_slashnephy_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-pages-challenge-slashnephy.cydia"
  value   = "b269d976763fb337800db41bb78d97"
  type    = "TXT"
}
resource "cloudflare_record" "txt_github_verify_slashnephy_spica" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-pages-challenge-slashnephy.spica"
  value   = "14400f193e1665a52e3788180c7230"
  type    = "TXT"
}

resource "cloudflare_record" "txt_keybase_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "_keybase"
  value   = "keybase-site-verification=PylHNVjnYCgQBcZdDx7h9AqqtLjNbOw6-qPYrJ5AMlI"
  type    = "TXT"
}

resource "cloudflare_record" "txt_sonatype_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "https://issues.sonatype.org/browse/OSSRH-64134"
  type    = "TXT"
}
