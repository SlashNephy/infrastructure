resource "mackerel_service" "external_rhodium" {
  name = "Rhodium"
}

resource "mackerel_monitor" "external_rhodium" {
  name = format("%s に疎通できない", var.external_urls["rhodium"].url)

  external {
    method                 = "GET"
    url                    = var.external_urls["rhodium"].url
    service                = mackerel_service.external_rhodium.name
    response_time_warning  = 1000
    response_time_critical = 3000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.external_urls["rhodium"].user, var.external_urls["rhodium"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
