resource "cloudflare_record" "caa_issuewild" {
  zone_id = cloudflare_zone.zone.id
  name    = "starry.blue"
  type    = "CAA"

  data {
    flags = "0"
    tag   = "issuewild"
    value = "letsencrypt.org"
  }
}

resource "cloudflare_record" "caa_issue" {
  zone_id = cloudflare_zone.zone.id
  name    = "starry.blue"
  type    = "CAA"

  data {
    flags = "0"
    tag   = "issue"
    value = "letsencrypt.org"
  }
}

resource "cloudflare_record" "caa_iodef" {
  zone_id = cloudflare_zone.zone.id
  name    = "starry.blue"
  type    = "CAA"

  data {
    flags = "0"
    tag   = "iodef"
    value = "mailto:webmaster@starry.blue"
  }
}
