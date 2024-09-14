resource "mackerel_service" "switchbot" {
  name = "SwitchBot"
}

locals {
  battery_device_ids = toset([
    "D86D1D631EBA",
    "E7A5BDF31DCE",
  ])
}

resource "mackerel_monitor" "switchbot_battery" {
  for_each = local.battery_device_ids
  name     = format("バッテリー残量が低下している (%s)", each.value)

  service_metric {
    service  = mackerel_service.switchbot.name
    metric   = format("switchbot.battery.%s", each.value)
    operator = "<"
    duration = 1
    warning  = "30"
    critical = "10"
    // device states not synchronized with server でメトリックが登録されないことがあるので12時間はメトリックの欠損を許可
    missing_duration_warning  = 720
    missing_duration_critical = 1440
  }
}
