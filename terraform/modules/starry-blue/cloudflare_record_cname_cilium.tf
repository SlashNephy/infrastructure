resource "mackerel_service" "cilium" {
  name = "Lily_Cilium"
}

resource "mackerel_monitor" "cilium" {
  name = "cilium.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://cilium.starry.blue/healthz"
    expected_status_code              = 200
    service                           = mackerel_service.cilium.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
