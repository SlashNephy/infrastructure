resource "mackerel_monitor" "loadavg1" {
  name = "loadavg1 が高すぎる"

  host_metric {
    metric             = "loadavg1"
    operator           = ">"
    warning            = "25"
    critical           = "50"
    duration           = 3
    max_check_attempts = 3
    scopes             = [mackerel_role.server.id]
  }
}
