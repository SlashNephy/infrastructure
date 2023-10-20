resource "cloudflare_notification_policy_webhooks" "discord" {
  account_id = cloudflare_account.account.id

  name   = "Cloudflare"
  url    = data.onepassword_item.cloudflare_notification_webhook.url
  secret = data.onepassword_item.cloudflare_notification_webhook.password
}

data "onepassword_item" "cloudflare_notification_webhook" {
  vault = data.onepassword_vault.terraform.uuid
  uuid  = "vbmhmitpuh7xovg6zc3y7zmi2e"
}
