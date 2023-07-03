resource "mackerel_notification_group" "default" {
  name              = "Default"
  child_channel_ids = [
    mackerel_channel.general.id,
  ]
}
