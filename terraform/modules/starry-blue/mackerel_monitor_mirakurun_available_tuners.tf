resource "mackerel_monitor" "mirakurun_available_tuners" {
  name = "空きチューナーが減少している"

  host_metric {
    metric             = "custom.mirakurun.tuners.free"
    operator           = "<"
    warning            = "3"
    critical           = "1"
    duration           = 1
    max_check_attempts = 1
    scopes             = ["Production:Server"]
  }
}
