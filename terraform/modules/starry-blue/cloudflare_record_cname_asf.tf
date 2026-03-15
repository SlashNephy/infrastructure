resource "mackerel_service" "asf" {
  name = "Lily_ArchSteamFarm"
}

resource "mackerel_monitor" "asf" {
  name = "asf.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://asf.starry.blue/healthcheck"
    expected_status_code              = 200
    service                           = mackerel_service.asf.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
