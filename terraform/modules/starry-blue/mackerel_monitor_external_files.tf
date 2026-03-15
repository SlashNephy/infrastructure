resource "mackerel_monitor" "files" {
  name = "files.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://files.starry.blue/health"
    expected_status_code              = 200
    service                           = mackerel_service.production.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
