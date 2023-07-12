resource "mackerel_monitor" "nvme0_temperature" {
  name = "ストレージ温度が高すぎる (nvme0)"

  host_metric {
    metric             = "custom.telegraf.smart_attribute.device-nvme0_host-lily_model-Samsung_SSD_970_EVO_250GB_name-Temperature_Sensor_1_serial_no-S465NB0K407096Z.raw_value"
    operator           = ">"
    warning            = "50"
    critical           = "60"
    duration           = 3
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
