resource "mackerel_downtime" "weekly" {
  name     = "定期再起動"
  start    = 1688324400
  duration = 120

  recurrence {
    interval = 1
    type     = "weekly"
    weekdays = ["Monday"]
  }

  monitor_scopes = [
    mackerel_monitor.connectivity.id,
    mackerel_monitor.mirakurun.id,
    mackerel_monitor.mirakurun_api.id,
    mackerel_monitor.mirakurun_api_v6.id,
    mackerel_monitor.mahiron.id,
    mackerel_monitor.mahiron_api.id,
    mackerel_monitor.mahiron_api_v6.id,
    mackerel_monitor.epgstation.id,
    mackerel_monitor.epgstation_api.id,
    mackerel_monitor.epgstation_api_v6.id
  ]
}
