resource "cloudflare_record" "txt_google_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  content = "google-site-verification=CqG0H3T0SQtGDVumMvFz0u6N_W0QrsN_rHFlIC4_y1U"
  type    = "TXT"
}
