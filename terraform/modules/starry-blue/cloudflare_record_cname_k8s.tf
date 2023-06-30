resource "cloudflare_record" "cname_k8s" {
  zone_id = cloudflare_zone.zone.id
  name    = "k8s"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
