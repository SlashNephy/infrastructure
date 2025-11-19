terraform {
  required_version = "~> 1.14.0"

  cloud {
    organization = "StarryBlueSky"
    workspaces {
      name = "infrastructure"
    }
  }
}

module "starry-blue" {
  source                                 = "./modules/starry-blue"
  cloudflare_api_token                   = var.cloudflare_api_token
  general_slack_webhook_url              = var.general_slack_webhook_url
  dtv_slack_webhook_url                  = var.dtv_slack_webhook_url
  cloudflare_notification_webhook_url    = var.cloudflare_notification_webhook_url
  cloudflare_notification_webhook_secret = var.cloudflare_notification_webhook_secret
}
