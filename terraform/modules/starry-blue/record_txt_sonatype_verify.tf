resource "cloudflare_record" "txt_sonatype_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = cloudflare_zone.zone.zone
  value   = "https://issues.sonatype.org/browse/OSSRH-64134"
  type    = "TXT"
}
