terraform {
  required_version = "1.3.9"

  cloud {
    organization = "StarryBlueSky"
    workspaces {
      name = "infrastructure"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 3"
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
}
