resource "mackerel_monitor" "anomaly_detection" {
  name = "異常検知"

  anomaly_detection {
    scopes               = ["Production:Server"]
    warning_sensitivity  = "sensitive"
    critical_sensitivity = "normal"
    max_check_attempts   = 3
  }
}
