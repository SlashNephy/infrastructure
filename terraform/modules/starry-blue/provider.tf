terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.12.0"
    }
    mackerel = {
      source  = "mackerelio-labs/mackerel"
      version = "0.6.3"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
