resource "mackerel_service" "kubeclarity" {
  name = "Lily_KubeClarity"
}

resource "mackerel_monitor" "kubeclarity" {
  name = "kubeclarity.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://kubeclarity.starry.blue"
    expected_status_code              = 302 # TODO: アプリケーションに到達できるようにし 200 を確認する
    service                           = mackerel_service.kubeclarity.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
