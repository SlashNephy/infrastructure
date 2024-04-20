resource "cloudflare_record" "txt_spf" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "v=spf1 include:_spf.mx.cloudflare.net include:sendgrid.net include:_spf.google.com ~all"
  type    = "TXT"
}

resource "cloudflare_record" "txt_dmarc" {
  zone_id = cloudflare_zone.zone.id
  name    = "_dmarc"
  value   = "v=DMARC1; p=quarantine; rua=mailto:0ba6694f5bc7409c8af47777fb7da4ca@dmarc-reports.cloudflare.net"
  type    = "TXT"
}

// SendGrid
resource "cloudflare_record" "cname_em6974" {
  zone_id = cloudflare_zone.zone.id
  name    = "em6974"
  value   = "u43989568.wl069.sendgrid.net"
  type    = "CNAME"
}

resource "cloudflare_record" "cname_s1_domainkey" {
  zone_id = cloudflare_zone.zone.id
  name    = "s1._domainkey"
  value   = "s1.domainkey.u43989568.wl069.sendgrid.net"
  type    = "CNAME"
}

resource "cloudflare_record" "cname_s2_domainkey" {
  zone_id = cloudflare_zone.zone.id
  name    = "s2._domainkey"
  value   = "s2.domainkey.u43989568.wl069.sendgrid.net"
  type    = "CNAME"
}
