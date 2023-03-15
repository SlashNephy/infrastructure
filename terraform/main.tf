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
      version = "4.1.0"
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
  lily_network                    = var.lily_network
  bbc_network                     = var.bbc_network
  anime_omikuji_anilist_client_id = var.anime_omikuji_anilist_client_id
}
