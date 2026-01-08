resource "cloudflare_record" "caa_issuewild" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  type    = "CAA"

  data {
    flags = "0"
    tag   = "issuewild"
    value = "letsencrypt.org"
  }
}

resource "cloudflare_record" "caa_issue" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  type    = "CAA"

  data {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
}

# https://help.hatenablog.com/entry/customdomain#%E9%AB%98%E5%BA%A6%E3%81%AA%E8%A8%AD%E5%AE%9ACAA%E3%83%AC%E3%82%B3%E3%83%BC%E3%83%89%E3%81%AE%E8%A8%AD%E5%AE%9A%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6
resource "cloudflare_record" "caa_issue_amazon_acm" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  type    = "CAA"

  data {
    flags = "0"
    tag   = "issue"
    value = "amazon.com"
  }
}

resource "cloudflare_record" "caa_iodef" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  type    = "CAA"

  data {
    flags = "0"
    tag   = "iodef"
    value = "mailto:${local.webmaster_email_address}"
  }
}
