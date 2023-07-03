resource "mackerel_channel" "dtv" {
  name = "#dtv"

  slack {
    url                 = var.dtv_slack_webhook_url
    enabled_graph_image = true
    events              = [
      "alert"
    ]
  }
}
