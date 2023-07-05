resource "mackerel_monitor" "cpu_iowait" {
  name = "CPU iowait が異常となっている"

  host_metric {
    metric             = "cpu.iowait.percentage"
    operator           = ">"
    warning            = "150"
    critical           = "200"
    duration           = 5
    max_check_attempts = 3
    scopes             = [mackerel_role.server.id]
  }
}
