terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.28.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.13.3"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
