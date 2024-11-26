terraform {
  required_version = "~> 1.9.0"

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
  mackerel_api_key                       = var.mackerel_api_key
  general_slack_webhook_url              = var.general_slack_webhook_url
  dtv_slack_webhook_url                  = var.dtv_slack_webhook_url
  cloudflare_notification_webhook_url    = var.cloudflare_notification_webhook_url
  cloudflare_notification_webhook_secret = var.cloudflare_notification_webhook_secret
}
