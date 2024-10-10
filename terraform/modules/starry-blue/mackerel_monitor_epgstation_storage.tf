resource "mackerel_monitor" "epgstation_storage" {
  name                  = "録画ストレージの空き容量が低下している"
  memo                  = "EPGStation の自動削除が機能していません。手動で不要なファイルを削除してください。"
  notification_interval = 180 // 3 hours

  host_metric {
    metric             = "custom.epgstation.storages.available"
    operator           = "<"
    warning            = "500000000000" // 500 GB
    critical           = "250000000000" // 250 GB
    duration           = 1
    max_check_attempts = 1
    scopes             = [mackerel_role.server.id]
  }
}
