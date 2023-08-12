resource "mackerel_service" "external_manganese" {
  name = "Manganese"
}

resource "mackerel_monitor" "external_manganese" {
  name = format("%s に疎通できない", data.onepassword_item.external-manganese_credential.url)

  external {
    method                 = "GET"
    url                    = data.onepassword_item.external-manganese_credential.url
    service                = mackerel_service.external_manganese.name
    response_time_warning  = 1000
    response_time_critical = 3000
    response_time_duration = 3
    max_check_attempts     = 3
    headers                = {
      Cache-Control = "no-cache"
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.external-manganese_credential.username, data.onepassword_item.external-manganese_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 14
    certification_expiration_critical = 7
    follow_redirect                   = false
  }
}
