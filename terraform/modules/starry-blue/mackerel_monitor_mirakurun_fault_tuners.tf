resource "mackerel_monitor" "mirakurun_fault_tuners" {
  name = "チューナーが fault 状態になっている"

  host_metric {
    metric             = "custom.mirakurun.tuners.fault"
    operator           = ">"
    critical           = "0"
    duration           = 1
    max_check_attempts = 1
    scopes             = ["Production:Server"]
  }
}
