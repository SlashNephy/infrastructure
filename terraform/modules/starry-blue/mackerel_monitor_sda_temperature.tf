resource "mackerel_monitor" "sda_temperature" {
  name = "ストレージ温度が高すぎる (sda)"

  host_metric {
    metric             = "custom.telegraf.smart_attribute.capacity-4000787030016_device-sda_enabled-Enabled_fail--_flags--O---K_host-lily_id-194_model-WDC_WD42PURZ-85B4YY0_name-Temperature_Celsius_power-ACTIVE_serial_no-WD-WX32A92DU945_wwn-50014ee2c01b7b3c.raw_value"
    operator           = ">"
    warning            = "50"
    critical           = "60"
    duration           = 3
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
