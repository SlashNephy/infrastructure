resource "cloudflare_record" "txt_dmarc" {
  zone_id = cloudflare_zone.zone.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=quarantine; rua=mailto:${local.webmaster_email_address}"
  type    = "TXT"
}
