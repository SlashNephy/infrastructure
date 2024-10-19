resource "cloudflare_record" "txt_github_verify_slashnephy_cydia" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-pages-challenge-slashnephy.cydia"
  content = "b269d976763fb337800db41bb78d97"
  type    = "TXT"
}
