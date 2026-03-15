resource "mackerel_service" "grafana_alloy" {
  name = "Lily_Grafana-Alloy"
}

resource "mackerel_monitor" "grafana_alloy" {
  name = "grafana-alloy.starry.blue"

  external {
    method = "GET"
    url    = "https://grafana-alloy.starry.blue"
    # expected_status_code              = 200
    service                           = mackerel_service.grafana_alloy.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
