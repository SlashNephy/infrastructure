terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.17.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.8.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
