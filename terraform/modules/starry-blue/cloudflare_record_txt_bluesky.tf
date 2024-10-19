resource "cloudflare_record" "txt_bluesky" {
  zone_id = cloudflare_zone.zone.id
  name    = "_atproto"
  content = "did=did:plc:blaqv5fitmt5jbhfqjizh6ua"
  type    = "TXT"
}
