terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.23.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.12.1"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
