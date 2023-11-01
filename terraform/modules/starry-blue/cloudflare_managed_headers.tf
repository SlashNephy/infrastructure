resource "cloudflare_managed_headers" "default" {
  zone_id = cloudflare_zone.zone.id

  managed_request_headers {
    enabled = true
    id      = "add_visitor_location_headers"
  }

  managed_response_headers {
    enabled = true
    id      = "remove_x-powered-by_header"
  }

  managed_response_headers {
    enabled = true
    id      = "add_security_headers"
  }
}
