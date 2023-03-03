resource "cloudflare_ruleset" "http_request_dynamic_redirect" {
  zone_id = local.cloudflare_zone_id
  name    = "http_request_dynamic_redirect"
  kind    = "zone"
  phase   = "http_request_dynamic_redirect"

  rules {
    enabled     = true
    description = "www.starry.blue -> starry.blue"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "www.starry.blue")
    EOT
  }

  rules {
    enabled     = true
    description = "starry.blue -> spica.starry.blue"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://spica.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "starry.blue")
    EOT
  }

  rules {
    enabled     = true
    description = "apps.starry.blue -> ${local.cloudflare_access_domain}"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 302
        target_url {
          value = "https://${local.cloudflare_access_domain}"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (http.host eq "apps.starry.blue" and http.request.uri.path eq "/")
    EOT
  }

  rules {
    enabled     = true
    description = "廃止 (apps.starry.blue/atmos-token-distributor)"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://basic.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (starts_with(http.request.full_uri, "https://apps.starry.blue/atmos-token-distributor"))
    EOT
  }

  rules {
    enabled     = true
    description = "廃止 (apps.starry.blue/miniserve)"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://files.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (starts_with(http.request.full_uri, "https://apps.starry.blue/miniserve"))
    EOT
  }

  rules {
    enabled     = true
    description = "廃止 (apps.starry.blue/mirakurun)"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://mirakurun.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (starts_with(http.request.full_uri, "https://apps.starry.blue/mirakurun"))
    EOT
  }

  rules {
    enabled     = true
    description = "廃止 (apps.starry.blue/stella)"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://stella.starry.blue"
        }
        preserve_query_string = false
      }
    }

    expression = <<-EOT
      (starts_with(http.request.full_uri, "https://apps.starry.blue/stella"))
    EOT
  }

  rules {
    enabled     = true
    description = "廃止 (atmos.starry.blue)"
    action      = "redirect"
    action_parameters {
      from_value {
        status_code = 301
        target_url {
          value = "https://epgstation.starry.blue"
        }
        preserve_query_string = false
      }
    }

    # TODO: /mirakurun 廃止後、式を更新する
    expression = <<-EOT
      (http.host eq "atmos.starry.blue" and not starts_with(http.request.uri.path, "/mirakurun"))
    EOT
  }
}
