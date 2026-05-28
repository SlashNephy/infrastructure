terraform {
  required_version = "~> 1.15.0"

  cloud {
    organization = "StarryBlueSky"
    workspaces {
      name = "infrastructure"
    }
  }
}

module "starry-blue" {
  source                    = "./modules/starry-blue"
  cloudflare_api_token      = var.cloudflare_api_token
  general_slack_webhook_url = var.general_slack_webhook_url
  dtv_slack_webhook_url     = var.dtv_slack_webhook_url
}
