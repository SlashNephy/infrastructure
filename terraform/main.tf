terraform {
  required_version = "~> 1.16.0"

  cloud {
    organization = "StarryBlueSky"
    workspaces {
      name = "infrastructure"
    }
  }
}

module "starry-blue" {
  source               = "./modules/starry-blue"
  cloudflare_api_token = var.cloudflare_api_token
}
