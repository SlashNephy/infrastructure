locals {
  webmaster_email_address  = "webmaster@starry.blue"
  github_organization_name = "StarryBlueSky"
}

variable "cloudflare_api_token" {
  type = string
}

variable "general_slack_webhook_url" {
  type = string
}

variable "dtv_slack_webhook_url" {
  type = string
}

variable "cloudflare_notification_webhook_url" {
  type = string
}

variable "cloudflare_notification_webhook_secret" {
  type = string
}
