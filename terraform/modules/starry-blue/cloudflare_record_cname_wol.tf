resource "mackerel_service" "wol" {
  name = "Lily_wolweb"
}

resource "mackerel_monitor" "wol" {
  name = "wol.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://wol.starry.blue/health"
    expected_status_code              = 200
    service                           = mackerel_service.wol.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
