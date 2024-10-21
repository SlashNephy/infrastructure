terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "2.1.2"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.39.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.4.0"
    }
  }
}

provider "onepassword" {
  url   = "https://op-tfc.starry.blue"
  token = var.onepassword_connect_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "mackerel" {
  api_key = var.mackerel_api_key
}
