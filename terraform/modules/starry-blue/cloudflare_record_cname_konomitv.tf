resource "mackerel_service" "konomitv" {
  name = "Lily_KonomiTV"
}

resource "mackerel_monitor" "konomitv" {
  name = "konomitv.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://konomitv.starry.blue/api/version"
    expected_status_code              = 200
    service                           = mackerel_service.konomitv.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
