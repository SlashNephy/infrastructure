resource "mackerel_service" "external_selenium" {
  name = "Selenium"
}

resource "mackerel_monitor" "external_selenium" {
  name = format("%s に疎通できない", var.external_urls["selenium"].url)

  external {
    method                 = "GET"
    url                    = var.external_urls["selenium"].url
    service                = mackerel_service.external_selenium.name
    response_time_warning  = 1000
    response_time_critical = 3000
    response_time_duration = 3
    max_check_attempts     = 1
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", var.external_urls["selenium"].user, var.external_urls["selenium"].password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 30
    certification_expiration_critical = 15
    follow_redirect                   = false
  }
}
