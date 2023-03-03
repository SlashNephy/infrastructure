resource "cloudflare_ruleset" "config" {
  zone_id = local.cloudflare_zone_id
  name    = "Disable Content Modification"
  kind    = "zone"
  phase   = "http_config_settings"

  rules {
    enabled = true
    action  = "set_config"
    action_parameters {
      autominify {
        css  = false
        html = false
        js   = false
      }
      rocket_loader = false
    }

    expression = <<-EOT
      (http.host in {
        "apps.starry.blue"
        "asf.starry.blue"
        "jupyter.starry.blue"
      })
    EOT
  }
}
