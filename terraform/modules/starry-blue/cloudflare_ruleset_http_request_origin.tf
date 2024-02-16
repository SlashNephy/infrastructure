resource "cloudflare_ruleset" "http_request_origin" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_request_origin"
  kind    = "zone"
  phase   = "http_request_origin"

  rules {
    enabled     = true
    description = "Use :13443 Origin"
    action      = "route"
    action_parameters {
      origin {
        port = 13443
      }
    }

    expression = <<-EOT
      (http.host in {
        "${cloudflare_record.cname_ai.hostname}"
        "${cloudflare_record.cname_amq_proxy.hostname}"
        "${cloudflare_record.cname_apps.hostname}"
        "${cloudflare_record.cname_argocd.hostname}"
        "${cloudflare_record.cname_asf.hostname}"
        "${cloudflare_record.cname_basic.hostname}"
        "${cloudflare_record.cname_code.hostname}"
        "${cloudflare_record.cname_epgstation.hostname}"
        "${cloudflare_record.cname_files.hostname}"
        "${cloudflare_record.cname_juicefs.hostname}"
        "${cloudflare_record.cname_k8s.hostname}"
        "${cloudflare_record.cname_konomitv.hostname}"
        "${cloudflare_record.cname_kubeclarity.hostname}"
        "${cloudflare_record.cname_mahiron.hostname}"
        "${cloudflare_record.cname_nebula_api.hostname}"
        "${cloudflare_record.cname_op-tfc.hostname}"
        "${cloudflare_record.cname_router.hostname}"
        "${cloudflare_record.cname_search.hostname}"
        "${cloudflare_record.cname_traefik.hostname}"
        "${cloudflare_record.cname_whoami.hostname}"
        "${cloudflare_record.cname_wol.hostname}"
      })
    EOT
  }
}
