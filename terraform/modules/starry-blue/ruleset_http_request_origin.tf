resource "cloudflare_ruleset" "http_request_origin" {
  zone_id = cloudflare_zone.zone.id
  name    = "http_request_origin"
  kind    = "zone"
  phase   = "http_request_origin"

  rules {
    enabled     = true
    description = "Use :8443 Origin"
    action      = "route"
    action_parameters {
      origin {
        port = 8443
      }
    }

    expression = <<-EOT
      (http.host in {
        "${cloudflare_record.cname_anemos.hostname}"
        "${cloudflare_record.cname_apps.hostname}"
        "${cloudflare_record.cname_argocd.hostname}"
        "${cloudflare_record.cname_asf.hostname}"
        "${cloudflare_record.cname_atmos.hostname}"
        "${cloudflare_record.cname_basic.hostname}"
        "${cloudflare_record.cname_code.hostname}"
        "${cloudflare_record.cname_epgstation.hostname}"
        "${cloudflare_record.cname_files.hostname}"
        "${cloudflare_record.cname_jupyter.hostname}"
        "${cloudflare_record.cname_k8s.hostname}"
        "${cloudflare_record.cname_keel.hostname}"
        "${cloudflare_record.cname_konomitv.hostname}"
        "${cloudflare_record.cname_mahiron.hostname}"
        "${cloudflare_record.cname_mirakurun.hostname}"
        "${cloudflare_record.cname_owncast.hostname}"
        "${cloudflare_record.cname_rclone.hostname}"
        "${cloudflare_record.cname_rustpad.hostname}"
        "${cloudflare_record.cname_search.hostname}"
        "${cloudflare_record.cname_stella.hostname}"
        "${cloudflare_record.cname_traefik.hostname}"
        "${cloudflare_record.cname_whoami.hostname}"
        "${cloudflare_record.cname_wol.hostname}"
      })
    EOT
  }
}
