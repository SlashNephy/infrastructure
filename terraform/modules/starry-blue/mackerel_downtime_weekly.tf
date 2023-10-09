resource "mackerel_downtime" "weekly" {
  name     = "定期再起動"
  start    = 1696784400
  duration = 720

  recurrence {
    interval = 1
    type     = "weekly"
    weekdays = ["Monday"]
  }
}
