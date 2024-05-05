resource "mackerel_service" "external_rhodium" {
  name = "Rhodium"
}

resource "mackerel_monitor" "external_rhodium" {
  name    = format("%s に疎通できない", data.onepassword_item.external-rhodium_credential.url)
  is_mute = true

  external {
    method                 = "GET"
    url                    = data.onepassword_item.external-rhodium_credential.url
    service                = mackerel_service.external_rhodium.name
    response_time_warning  = 3000
    response_time_critical = 5000
    response_time_duration = 3
    max_check_attempts     = 3
    headers = {
      Authorization = "Basic ${base64encode(format("%s:%s", data.onepassword_item.external-rhodium_credential.username, data.onepassword_item.external-rhodium_credential.password))}"
    }
    contains_string                   = "{"
    certification_expiration_warning  = 7
    certification_expiration_critical = 3
    follow_redirect                   = false
  }

  depends_on = [data.onepassword_item.external-rhodium_credential]
}
