resource "mackerel_service" "external_uranium" {
  name = "Uranium"
}

resource "mackerel_monitor" "external_uranium" {
  name = format("%s に疎通できない", data.onepassword_item.external-uranium_credential.url)

  external {
    method                 = "GET"
    url                    = data.onepassword_item.external-uranium_credential.url
    service                = mackerel_service.external_uranium.name
    response_time_warning  = 1000
    response_time_critical = 3000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.external-uranium_credential.username, data.onepassword_item.external-uranium_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.external-uranium_credential]
}
