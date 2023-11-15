resource "mackerel_service" "switchbot" {
  name = "SwitchBot"
}

locals {
  battery_device_ids = toset([
    "D86D1D631EBA",
    "E68A1F4AC9EC",
    "E7A5BDF31DCE",
  ])
}

resource "mackerel_monitor" "switchbot_battery" {
  for_each = local.battery_device_ids
  name     = format("バッテリー残量が低下している (%s)", each.value)

  service_metric {
    service                   = mackerel_service.switchbot.name
    metric                    = format("switchbot.battery.%s", each.value)
    operator                  = "<"
    duration                  = 1
    warning                   = "30"
    critical                  = "10"
    missing_duration_warning  = 10
    missing_duration_critical = 30
  }
}
