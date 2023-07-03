resource "mackerel_service" "production" {
  name = "Production"
}

resource "mackerel_role" "server" {
  name    = "Server"
  service = mackerel_service.production.name
}
