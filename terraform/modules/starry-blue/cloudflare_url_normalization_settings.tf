// https://developers.cloudflare.com/rules/normalization/
resource "cloudflare_url_normalization_settings" "default" {
  zone_id = cloudflare_zone.zone.id
  type    = "cloudflare"
  scope   = "both"
}
