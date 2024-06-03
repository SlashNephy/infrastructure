resource "cloudflare_record" "cname_zero_ssl_verify" {
  zone_id = cloudflare_zone.zone.id
  name    = "_3335B0FD3B631E8CFB6F3508E480BD09.dns"
  value   = "FC30F1F227F8B562E855021BDFF33CC4.30E939B8461358691AFF4FDFC423A6F3.c2bd6d22c368d07.comodoca.com"
  type    = "CNAME"
  proxied = true
}
