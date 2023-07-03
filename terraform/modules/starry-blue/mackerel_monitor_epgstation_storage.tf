resource "mackerel_monitor" "epgstation_storage" {
  name = "録画ストレージの空き容量が低下している"

  host_metric {
    metric             = "custom.epgstation.storages.available"
    operator           = "<"
    warning            = "32212254720"
    critical           = "21474836480"
    duration           = 1
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
