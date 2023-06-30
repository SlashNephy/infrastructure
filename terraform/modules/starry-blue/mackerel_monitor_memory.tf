resource "mackerel_monitor" "memory" {
  name = "メモリ使用率が異常となっている"

  host_metric {
    metric             = "Memory %"
    operator           = ">"
    warning            = "80"
    critical           = "90"
    duration           = 3
    max_check_attempts = 1
    scopes             = ["Production:Server"]
  }
}
