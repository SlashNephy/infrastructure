resource "mackerel_service" "external_manganese" {
  name = "Manganese"
}

resource "mackerel_monitor" "external_manganese" {
  name = format("%s に疎通できない", var.external_urls["manganese"].url)

  external {
    method                 = "GET"
    url                    = var.external_urls["manganese"].url
    service                = mackerel_service.external_manganese.name
    response_time_warning  = 1000
    response_time_critical = 3000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.external_urls["manganese"].user, var.external_urls["manganese"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
