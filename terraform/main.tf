terraform {
  required_version = "1.5.2"

  cloud {
    organization = "StarryBlueSky"
    workspaces {
      name = "infrastructure"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.1.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.3.2"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

module "starry-blue" {
  source                          = "./modules/starry-blue"
  cloudflare_api_token            = var.cloudflare_api_token
  github_oauth_client_secret      = var.github_oauth_client_secret
  email_routing_catch_all_address = var.email_routing_catch_all_address
  mackerel_api_key                = var.mackerel_api_key
}
