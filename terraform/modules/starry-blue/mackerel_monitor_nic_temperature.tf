resource "mackerel_monitor" "nic_temperature" {
  name = "NIC の温度が高すぎる"

  host_metric {
    metric             = "custom.telegraf.sensors.chip-enp1s0-pci-0100_feature-mac_temperature_host-lily.temp_input"
    operator           = ">"
    warning            = "80"
    critical           = "85"
    duration           = 3
    max_check_attempts = 1
    scopes             = ["Production:Server"]
  }
}
