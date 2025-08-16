resource "mackerel_notification_group" "dtv" {
  name = "DTV"
  child_channel_ids = [
    mackerel_channel.general.id,
    mackerel_channel.dtv.id,
  ]

  monitor {
    id = mackerel_monitor.mahiron.id
  }
  monitor {
    id = mackerel_monitor.epgstation_conflicts.id
  }
  monitor {
    id = mackerel_monitor.epgstation_storage.id
  }
  monitor {
    id = mackerel_monitor.epgstation.id
  }
  monitor {
    id = mackerel_monitor.connectivity.id
  }
  monitor {
    id = "5x6yDZXh1VN" # そろそろホストマシンのストレージが枯れる！
  }
}
