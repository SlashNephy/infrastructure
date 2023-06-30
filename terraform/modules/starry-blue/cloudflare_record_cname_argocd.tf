resource "cloudflare_record" "cname_argocd" {
  zone_id = cloudflare_zone.zone.id
  name    = "argocd"
  value   = cloudflare_record.a_gateway.hostname
  type    = "CNAME"
  proxied = true
}
