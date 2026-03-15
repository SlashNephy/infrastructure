resource "mackerel_service" "grafana" {
  name = "Lily_Grafana"
}

resource "mackerel_monitor" "grafana" {
  name = "grafana.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://grafana.starry.blue/api/health"
    expected_status_code              = 200
    service                           = mackerel_service.grafana.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
