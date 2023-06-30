resource "mackerel_monitor" "cpu" {
  name = "CPU 使用率が異常となっている"

  host_metric {
    metric             = "CPU %"
    operator           = ">"
    warning            = "80"
    critical           = "90"
    duration           = 3
    max_check_attempts = 1
    scopes             = ["Production:Server"]
  }
}
