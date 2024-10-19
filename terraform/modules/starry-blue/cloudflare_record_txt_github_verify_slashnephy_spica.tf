resource "cloudflare_record" "txt_github_verify_slashnephy_spica" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-pages-challenge-slashnephy.spica"
  content = "14400f193e1665a52e3788180c7230"
  type    = "TXT"
}
