resource "cloudflare_record" "txt_spf" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "v=spf1 include:_spf.mx.cloudflare.net include:sendgrid.net include:_spf.google.com ~all"
  type    = "TXT"
}
