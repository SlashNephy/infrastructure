resource "mackerel_notification_group" "dtv" {
  name              = "DTV"
  child_channel_ids = [
    mackerel_channel.dtv.id,
    mackerel_channel.general.id,
  ]

  monitor {
    id = mackerel_monitor.mirakurun_fault_tuners.id
  }
  monitor {
    id = mackerel_monitor.mirakurun_available_tuners.id
  }
  monitor {
    id = mackerel_monitor.mirakurun.id
  }
  monitor {
    id = mackerel_monitor.mirakurun_api.id
  }
  #  monitor {
  #    id = mackerel_monitor.mirakurun_api_v6.id
  #  }
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
    id = mackerel_monitor.epgstation_api.id
  }
  #  monitor {
  #    id = mackerel_monitor.epgstation_api_v6.id
  #  }
  monitor {
    id = mackerel_monitor.external_manganese.id
  }
  monitor {
    id = mackerel_monitor.external_rhodium.id
  }
  monitor {
    id = mackerel_monitor.external_uranium.id
  }
  monitor {
    id = mackerel_monitor.external_selenium.id
  }
}
