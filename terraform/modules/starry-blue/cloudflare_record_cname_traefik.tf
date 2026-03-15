resource "mackerel_service" "traefik" {
  name = "Lily_Traefik"
}

resource "mackerel_monitor" "traefik" {
  name = "traefik.starry.blue"

  external {
    method                            = "GET"
    url                               = "https://traefik.starry.blue/health"
    expected_status_code              = 302 # TODO: アプリケーションに到達できるようにし 200 を確認する
    service                           = mackerel_service.traefik.name
    response_time_warning             = 5000
    response_time_critical            = 10000
    response_time_duration            = 5
    max_check_attempts                = 1
    certification_expiration_warning  = 30
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
