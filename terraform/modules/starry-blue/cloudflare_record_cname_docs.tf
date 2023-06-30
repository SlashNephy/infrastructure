// TODO: cname_docs
locals {
  docs_hostname = "docs.starry.blue"
}

resource "mackerel_service" "docs" {
  name = "docs-starry-blue"
}

resource "mackerel_monitor" "docs" {
  name = format("%s に疎通できない", local.docs_hostname)

  external {
    method                 = "GET"
    url                    = format("https://%s", local.docs_hostname)
    service                = mackerel_service.docs.name
    response_time_warning  = 500
    response_time_critical = 1000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control           = "no-cache"
      CF-Access-Client-Id     = var.cloudflare_access_client_id
      CF-Access-Client-Secret = var.cloudflare_access_client_secret
    }
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
