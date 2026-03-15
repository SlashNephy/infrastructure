resource "mackerel_service" "n8n" {
  name = "Lily_n8n"
}

resource "mackerel_monitor" "n8n" {
  name = "n8n.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://n8n.starry.blue/healthz"
    expected_status_code              = 200
    service                           = mackerel_service.n8n.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
