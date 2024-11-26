resource "cloudflare_notification_policy_webhooks" "discord" {
  account_id = cloudflare_account.account.id

  name   = "Cloudflare"
  url    = var.cloudflare_notification_webhook_url
  secret = var.cloudflare_notification_webhook_secret
}
