resource "cloudflare_record" "txt_github_verify_starrybluesky" {
  zone_id = cloudflare_zone.zone.id
  name    = "_github-challenge-starrybluesky"
  content = "0f0c3cea54"
  type    = "TXT"
}
