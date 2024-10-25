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
  source                    = "./modules/starry-blue"
  onepassword_connect_token = var.onepassword_connect_token
  cloudflare_api_token      = var.cloudflare_api_token
  mackerel_api_key          = var.mackerel_api_key
}
