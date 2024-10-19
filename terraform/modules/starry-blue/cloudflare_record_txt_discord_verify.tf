resource "cloudflare_record" "txt_discord_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "_discord"
  content = "dh=861428ac00daee6a76aee35395a7e40b0b312f89"
  type    = "TXT"
}
