resource "mackerel_channel" "general" {
  name = "#mackerel"

  slack {
    url                 = var.general_slack_webhook_url
    enabled_graph_image = true
    events              = [
      "alert",
      "alertGroup",
      "hostRegister",
      "hostRetire",
      "hostStatus",
    ]
  }

  depends_on = [var.general_slack_webhook_url]
}
