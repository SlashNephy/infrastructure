resource "mackerel_monitor" "cpu_temperature" {
  name = "CPU 温度が高すぎる"

  host_metric {
    metric             = "custom.telegraf.temp.host-lily_sensor-coretemp_package_id_0.temp"
    operator           = ">"
    warning            = "70"
    critical           = "80"
    duration           = 3
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
