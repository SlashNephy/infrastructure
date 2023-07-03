resource "mackerel_monitor" "epgstation_conflicts" {
  name = "コンフリクトした録画ルールがある"

  host_metric {
    metric             = "custom.epgstation.reservation.conflicts"
    operator           = ">"
    critical           = "0"
    duration           = 1
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
