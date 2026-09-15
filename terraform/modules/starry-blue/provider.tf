terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.24.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.13.2"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
