resource "mackerel_service" "authentik" {
  name = "Lily_Authentik"
}

resource "mackerel_monitor" "authentik" {
  name = "id.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://id.starry.blue/-/health/live/"
    expected_status_code              = 200
    service                           = mackerel_service.authentik.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
