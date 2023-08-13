resource "mackerel_channel" "dtv" {
  name = "#dtv"

  slack {
    url                 = data.onepassword_item.dtv_slack_webhook_url.password
    enabled_graph_image = true
    events              = [
      "alert"
    ]
  }

  depends_on = [data.onepassword_item.dtv_slack_webhook_url]
}
