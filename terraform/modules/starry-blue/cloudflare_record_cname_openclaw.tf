resource "mackerel_service" "openclaw" {
  name = "Lily_openclaw"
}

resource "mackerel_monitor" "openclaw" {
  name = "openclaw.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://openclaw.starry.blue"
    expected_status_code              = 302
    service                           = mackerel_service.openclaw.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
