terraform {
  required_providers {
    onepassword = {
      source  = "1Password/onepassword"
      version = "1.4.3"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.33.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.3.2"
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
