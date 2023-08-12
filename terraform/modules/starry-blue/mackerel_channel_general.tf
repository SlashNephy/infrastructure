resource "mackerel_channel" "general" {
  name = "#mackerel"

  slack {
    url                 = data.onepassword_item.general_slack_webhook_url.password
    enabled_graph_image = true
    events              = [
      "alert",
      "alertGroup",
      "hostRegister",
      "hostRetire",
      "hostStatus",
    ]
  }
}
