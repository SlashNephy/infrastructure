resource "mackerel_service" "whoami" {
  name = "Lily_whoami"
}

resource "mackerel_monitor" "whoami" {
  name = "whoami.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://whoami.starry.blue"
    expected_status_code              = 200
    service                           = mackerel_service.whoami.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
